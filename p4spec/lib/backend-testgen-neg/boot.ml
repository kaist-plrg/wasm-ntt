module DCov_multi = Coverage.Dangling.Multi
module Sim = Runtime.Sim.Signature
module Evaluator = Wasm_phase_evaluator
module Episode = Wasm_episode
module Metadata = Wasm_coverage_metadata
module Phase = Wasm_phase
module Policy = Wasm_policy

type wasm_boot_diagnostic = {
  filename : string;
  category : string;
  message : string;
}

type wasm_boot_success = {
  coverage : DCov_multi.t;
  diagnostics : wasm_boot_diagnostic list;
}

type wasm_boot_failure = {
  filename : string;
  error : Phase.phase_error;
}

type wasm_seed_limit_failure =
  | SeedTimedOut
  | SeedStackOverflow
  | SeedOutOfMemory
  | SeedCancelled

exception Wasm_seed_timeout

let with_wasm_interrupt f =
  let previous_signal =
    Sys.signal Sys.sigint (Sys.Signal_handle (fun _ -> raise Sys.Break))
  in
  Fun.protect
    ~finally:(fun () -> Sys.set_signal Sys.sigint previous_signal)
    f

let observe_with_wasm_seed_limit ~seconds f =
  let previous_signal =
    Sys.signal Sys.sigalrm
      (Sys.Signal_handle (fun _ -> raise Wasm_seed_timeout))
  in
  let clear_instrumentation () =
    if Inst.Hook.is_active () then Inst.Hook.register []
  in
  Fun.protect
    ~finally:(fun () ->
      Unix.alarm 0 |> ignore;
      Sys.set_signal Sys.sigalrm previous_signal)
    (fun () ->
      with_wasm_interrupt (fun () ->
          if seconds > 0 then Unix.alarm seconds |> ignore;
          try Ok (f ()) with
          | Wasm_seed_timeout ->
              clear_instrumentation ();
              Error SeedTimedOut
          | Stack_overflow ->
              clear_instrumentation ();
              Error SeedStackOverflow
          | Out_of_memory ->
              clear_instrumentation ();
              Error SeedOutOfMemory
          | Sys.Break ->
              clear_instrumentation ();
              Error SeedCancelled))

(* Measure initial coverage of phantoms *)

(* On cold boot, first measure the coverage of the seed *)

let boot_cold (module Simulator : Sim.SIM) (spec : Sim.spec) (relname : string)
    (includes_p4 : string list) (excludes_p4 : string list)
    (dirname_p4 : string) : DCov_multi.t =
  let excludes_p4 = Util.Test.collect_excludes excludes_p4 in
  let filenames_p4 = Util.Filesys.collect_files ~suffix:".p4" dirname_p4 in
  let filenames_p4 =
    List.filter
      (fun filename_p4 ->
        not (List.exists (String.equal filename_p4) excludes_p4))
      filenames_p4
  in
  Runner.run_programs_with_dangling
    (module Simulator)
    spec relname includes_p4 filenames_p4

let init_coverage = function
  | Sim.SL spec -> DCov_multi.init spec
  | _ -> assert false

let diagnostic_of_instantiation filename = function
  | Phase.ImportResolutionFailed { message } ->
      { filename; category = "unknown import"; message }
  | _ -> assert false

let phase_error_message = function
  | Phase.SyntaxError (_, message) -> "syntax error: " ^ message
  | Phase.EpisodeError (_, message) -> "episode error: " ^ message
  | Phase.HarnessFailure (_, message) -> "harness failure: " ^ message
  | Phase.CoverageMetadataError message -> "coverage metadata error: " ^ message

let diagnostic_of_phase_error filename error =
  let category =
    match error with
    | Phase.SyntaxError _ -> "syntax error"
    | Phase.EpisodeError _ -> "episode error"
    | Phase.HarnessFailure _ -> "harness failure"
    | Phase.CoverageMetadataError _ -> "coverage metadata error"
  in
  { filename; category; message = phase_error_message error }

let diagnostic_of_seed_limit filename = function
  | SeedTimedOut ->
      { filename; category = "execution timeout"; message = "seed execution timed out" }
  | SeedStackOverflow ->
      { filename;
        category = "host stack overflow";
        message = "seed execution exceeded the host stack" }
  | SeedOutOfMemory ->
      { filename;
        category = "host out of memory";
        message = "seed execution exceeded host memory" }
  | SeedCancelled ->
      { filename; category = "cancelled"; message = "seed execution was cancelled" }

let ensure_hooks_inactive filename outcome =
  if Inst.Hook.is_active () then (
    Inst.Hook.register [];
    Error
      { filename;
        error =
          Phase.HarnessFailure
            (Util.Source.no_region,
             "instrumentation handler leaked while evaluating cold boot seed") })
  else outcome

let apply_with_seed_limit ~timeout_seed cover filename apply =
  match
    observe_with_wasm_seed_limit ~seconds:timeout_seed (fun () ->
        apply cover filename)
  with
  | Error SeedCancelled -> raise Sys.Break
  | Error failure ->
      Ok (cover, Some (diagnostic_of_seed_limit filename failure))
  | Ok (Error { error; _ }) ->
      Ok (cover, Some (diagnostic_of_phase_error filename error))
  | Ok (Ok outcome) -> Ok outcome

let fold_wasm_files ~coverage filenames apply =
  List.fold_left
    (fun (cover, diagnostics, failures) filename ->
      match ensure_hooks_inactive filename (apply cover filename) with
      | Ok (cover, diagnostic) ->
          let diagnostics =
            match diagnostic with
            | Some item -> item :: diagnostics
            | None -> diagnostics
          in
          (cover, diagnostics, failures)
      | Error failure -> (cover, diagnostics, failure :: failures))
    (coverage, [], []) filenames

let wasm_boot_cold ?(timeout_seed = Config.timeout_seed)
    (simulator : (module Sim.SIM)) (spec : Sim.spec)
    (phase : Config.wasm_phase) (dirname_wasm : string) :
    (wasm_boot_success, wasm_boot_failure list) result =
  let filenames_wasm =
    Util.Filesys.collect_files ~suffix:".wast" dirname_wasm |> List.sort String.compare
  in
  let env = Evaluator.make_env ~simulator ~spec in
  let apply_validation cover filename =
    match Evaluator.parse_validation_file filename with
    | Error error -> Error { filename; error }
    | Ok (module_list, expectation) -> (
        match Evaluator.evaluate_validation_with_dangling env module_list with
        | Error error -> Error { filename; error }
        | Ok (result, single) -> (
            match Evaluator.check_validation_expectation expectation result with
            | Error error -> Error { filename; error }
            | Ok () ->
                let { Policy.coverage; _ } = Policy.of_validation_result result in
                match coverage with
                | Some policy -> Ok (DCov_multi.extend_with_policy cover filename policy single)
                | None -> assert false))
  in
  let apply_instantiation cover filename =
    match Episode.parse_file filename with
    | Error error -> Error { filename; error }
    | Ok episode -> (
        match
          Evaluator.evaluate_instantiation_with_dangling env episode
            (Episode.target_value episode)
        with
        | Error error -> Error { filename; error }
        | Ok (result, single) -> (
            let { Policy.coverage = policy; emission } =
              Policy.of_instantiation_result result
            in
            match (policy, single, emission) with
            | Some policy, Some single, _ ->
                Ok (DCov_multi.extend_with_policy cover filename policy single, None)
            | None, None, Policy.DiagnosticOnly ->
                Ok (cover, Some (diagnostic_of_instantiation filename result))
            | _ ->
                Error
                  { filename;
                    error =
                      Phase.HarnessFailure
                        (Util.Source.no_region,
                         "candidate policy and Init coverage disagreed") }))
  in
  let apply_file cover filename =
    match phase with
    | Config.Validation ->
        Result.map (fun cover -> (cover, None)) (apply_validation cover filename)
    | Config.Instantiation ->
        apply_with_seed_limit ~timeout_seed cover filename apply_instantiation
  in
  let cover, diagnostics, failures =
    fold_wasm_files ~coverage:(init_coverage spec) filenames_wasm apply_file
  in
  match List.rev failures with
  | [] -> Ok { coverage = cover; diagnostics = List.rev diagnostics }
  | failures -> Error failures

let observation_prefix_paths filename =
  let prefix_path = Filename.chop_suffix filename ".wast" ^ ".prefix.wast.inc" in
  if Sys.file_exists prefix_path then [ prefix_path ] else []

let observation_coverage_policy =
  DCov_multi.
    { merge_hits = true;
      hit_confidence = Likely;
      record_close_misses = false }

let invocation_coverage_policy =
  DCov_multi.
    { merge_hits = true;
      hit_confidence = Exact;
      record_close_misses = false }

let wasm_boot_observe ?(timeout_seed = Config.timeout_seed)
    (simulator : (module Sim.SIM)) (spec : Sim.spec) ~(coverage : DCov_multi.t)
    (dirname_wasm : string) :
    (wasm_boot_success, wasm_boot_failure list) result =
  let filenames_wasm =
    Util.Filesys.collect_files ~suffix:".wast" dirname_wasm
    |> List.sort String.compare
  in
  let env = Evaluator.make_env ~simulator ~spec in
  let apply_observation cover filename =
    match
      Episode.parse_observation_file
        ~prefix_paths:(observation_prefix_paths filename)
        filename
    with
    | Error error -> Error { filename; error }
    | Ok episode -> (
        match
          Evaluator.evaluate_instantiation_with_dangling env episode
            (Episode.target_value episode)
        with
        | Error error -> Error { filename; error }
        | Ok ((Phase.ImportResolutionFailed _) as result, None) ->
            Ok (cover, Some (diagnostic_of_instantiation filename result))
        | Ok (_, Some single) ->
            Ok
              ( DCov_multi.extend_with_policy cover filename
                  observation_coverage_policy single,
                None )
        | Ok _ ->
            Error
              { filename;
                error =
                  Phase.HarnessFailure
                    (Util.Source.no_region,
                     "observation result and Init coverage disagreed") })
  in
  let apply_file cover filename =
    apply_with_seed_limit ~timeout_seed cover filename apply_observation
  in
  let cover, diagnostics, failures =
    fold_wasm_files ~coverage filenames_wasm apply_file
  in
  match List.rev failures with
  | [] -> Ok { coverage = cover; diagnostics = List.rev diagnostics }
  | failures -> Error failures

let wasm_boot_invoke ?(timeout_seed = Config.timeout_seed)
    (simulator : (module Sim.SIM)) (spec : Sim.spec) ~(coverage : DCov_multi.t)
    (dirname_wasm : string) :
    (wasm_boot_success, wasm_boot_failure list) result =
  let filenames_wasm =
    Util.Filesys.collect_files ~suffix:".wast" dirname_wasm
    |> List.sort String.compare
  in
  let env = Evaluator.make_env ~simulator ~spec in
  let apply_file cover filename =
    let cover_ref = ref cover in
    let observe () =
      match Episode.parse_invocation_file filename with
      | Error error -> Error error
      | Ok episode ->
          Evaluator.observe_invocation_with_dangling env episode
            ~on_observation:(fun
                (observation : Evaluator.invocation_observation) ->
              let path =
                Format.sprintf "%s#command=%d" filename
                  observation.command_index
              in
              cover_ref :=
                DCov_multi.extend_with_policy !cover_ref path
                  invocation_coverage_policy observation.coverage)
    in
    match observe_with_wasm_seed_limit ~seconds:timeout_seed observe with
    | Error SeedCancelled -> raise Sys.Break
    | Error failure ->
        Ok (!cover_ref, Some (diagnostic_of_seed_limit filename failure))
    | Ok (Error error) ->
        Ok (!cover_ref, Some (diagnostic_of_phase_error filename error))
    | Ok (Ok ()) -> Ok (!cover_ref, None)
  in
  let cover, diagnostics, failures =
    fold_wasm_files ~coverage filenames_wasm apply_file
  in
  match List.rev failures with
  | [] -> Ok { coverage = cover; diagnostics = List.rev diagnostics }
  | failures -> Error failures

let string_of_phase_error = phase_error_message

(* On warm boot, load the coverage from a file *)

let boot_warm (filename_cov : string) : DCov_multi.t =
  DCov_multi.load filename_cov

let wasm_boot_warm ~(phase : Config.wasm_phase) (filename_cov : string) :
    (DCov_multi.t, Phase.phase_error) result =
  Result.bind (Metadata.validate ~phase filename_cov) (fun () ->
      try Ok (DCov_multi.load filename_cov) with
      | Sys_error message ->
          Error
            (Phase.CoverageMetadataError
               (Format.sprintf "cannot load Wasm coverage %s: %s" filename_cov message))
      | exception_ ->
          Error
            (Phase.CoverageMetadataError
               (Format.sprintf "cannot load Wasm coverage %s: %s" filename_cov
                  (Printexc.to_string exception_))))
