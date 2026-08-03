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
  | Phase.LinkingRejected (Phase.UnknownImport { message }) ->
      { filename; category = "unknown import"; message }
  | Phase.TargetValidationRejected { message; _ } ->
      { filename; category = "target validation rejected"; message }
  | _ -> assert false

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

let wasm_boot_cold (simulator : (module Sim.SIM)) (spec : Sim.spec)
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
            match Evaluator.check_instantiation_oracle episode result with
            | Error error -> Error { filename; error }
            | Ok () ->
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
  let cover, diagnostics, failures =
    List.fold_left
      (fun (cover, diagnostics, failures) filename ->
        let outcome =
          match phase with
          | Config.Validation ->
              Result.map (fun cover -> (cover, None)) (apply_validation cover filename)
          | Config.Instantiation -> apply_instantiation cover filename
        in
        match ensure_hooks_inactive filename outcome with
        | Ok (cover, diagnostic) ->
            let diagnostics =
              match diagnostic with
              | Some item -> item :: diagnostics
              | None -> diagnostics
            in
            (cover, diagnostics, failures)
        | Error failure -> (cover, diagnostics, failure :: failures))
      (init_coverage spec, [], []) filenames_wasm
  in
  match List.rev failures with
  | [] -> Ok { coverage = cover; diagnostics = List.rev diagnostics }
  | failures -> Error failures

let string_of_phase_error = function
  | Phase.SyntaxError (_, message) -> "syntax error: " ^ message
  | Phase.EpisodeError (_, message) -> "episode error: " ^ message
  | Phase.RelationFailure failure ->
      Format.sprintf "relation failure in %s: %s" failure.Phase.relation
        failure.Phase.message
  | Phase.HarnessFailure (_, message) -> "harness failure: " ^ message
  | Phase.UnsupportedOutcome outcome -> "unsupported outcome: " ^ outcome
  | Phase.CoverageMetadataError message -> "coverage metadata error: " ^ message

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
