open Domain.Lib
open Lang.Il
open Util.Source

module Single = Coverage.Dangling.Single
module Dep = Runtime.Testgen_neg.Dep
module Episode = Wasm_episode
module Evaluator = Wasm_phase_evaluator
module Phase = Wasm_phase
module Policy = Wasm_policy
module Renderer = Wasm_episode_renderer

type seed =
  | ValidationSeed of Wasm_interface.Parse.expectation
  | InstantiationSeed of Episode.t

type semantic_result =
  | ValidationResult of Phase.validation_result
  | InstantiationResult of Phase.instantiation_result

type observation = {
  semantic : semantic_result;
  coverage : Single.t option;
  policy : Policy.candidate_policy;
  category : Policy.output_category option;
  emission : Policy.emission_policy;
}

type loaded_seed = {
  seed : seed;
  target : value;
  root : value;
  coverage : Single.t;
  graph : Dep.Graph.t;
  sources : VIdSet.t;
}

type seed_load = Reusable of loaded_seed | Diagnostic of string

type verified = {
  category : Policy.output_category;
  coverage : Single.t option;
}

let error message = Error (Phase.HarnessFailure (no_region, message))

let single_module_of_root root =
  match root.it with
  | ListV modules -> (
      match Value_array.to_list modules with
      | [ module_ ] -> (
          match Episode.module_entry_of_value module_ with
          | Ok _ -> Ok module_
          | Error _ as failure -> failure)
      | modules ->
          error
            (Format.asprintf
               "candidate shape error: expected exactly one module, got %d"
               (List.length modules)))
  | _ -> error "candidate shape error: expected a singleton module list"

let random_source_vids ~limit sources =
  sources |> VIdSet.elements |> Rand.random_sample limit

let filter_derivations sources derivations =
  List.filter (fun (vid, _) -> VIdSet.mem vid sources) derivations

let select_hits ~covermode ~intended hits =
  match covermode with
  | Modes.Relaxed -> hits
  | Modes.Strict ->
      if IIdSet.mem intended hits then IIdSet.singleton intended
      else IIdSet.empty

let observation semantic coverage policy =
  let category =
    match policy.Policy.emission with
    | Policy.MainArtifact category -> Some category
    | Policy.DiagnosticOnly | Policy.NoArtifact -> None
  in
  { semantic;
    coverage;
    policy;
    category;
    emission = policy.Policy.emission }

let evaluate env seed mutated_module =
  try
    match seed with
    | ValidationSeed _ ->
        let root = Episode.mutation_root mutated_module in
        Evaluator.evaluate_validation_with_dangling env root
        |> Result.map (fun (result, coverage) ->
               let policy = Policy.of_validation_result result in
               observation (ValidationResult result) (Some coverage) policy)
    | InstantiationSeed episode ->
        Evaluator.evaluate_instantiation_with_dangling env episode
          mutated_module
        |> Result.map (fun (result, coverage) ->
               let policy = Policy.of_instantiation_result result in
               observation (InstantiationResult result) coverage policy)
  with
  | Util.Error.RuntimeError (at, message) ->
      Error (Phase.HarnessFailure (at, message))
  | Z.Overflow ->
      Error
        (Phase.HarnessFailure
           (no_region, "integer conversion overflow in mutated candidate"))

let reusable ~seed ~target ~coverage ~graph =
  let root = Episode.mutation_root target in
  let sources =
    Dep.Graph.source_vids_under_root graph ~root ~exclude_root:true
  in
  Reusable { seed; target; root; coverage; graph; sources }

let clear_graph graph =
  Dep.Graph.G.reset graph.Dep.Graph.nodes;
  Dep.Graph.G.reset graph.Dep.Graph.edges

let load_validation_seed ~derive ~env filename =
  match Evaluator.parse_validation_file filename with
  | Error _ as failure -> failure
  | Ok (root, expectation) -> (
      match
        Evaluator.evaluate_validation_with_dangling_and_vdg ~derive env root
      with
      | Error _ as failure -> failure
      | Ok (result, coverage, graph) -> (
          match Evaluator.check_validation_expectation expectation result with
          | Error error ->
              clear_graph graph;
              Error error
          | Ok () -> (
              match single_module_of_root root with
              | Error error ->
                  clear_graph graph;
                  Error error
              | Ok target ->
                  match result with
                  | Phase.ValidationAccepted ->
                      Ok
                        (reusable ~seed:(ValidationSeed expectation) ~target
                           ~coverage ~graph)
                  | Phase.ValidationRejected _ ->
                      clear_graph graph;
                      Ok
                        (Diagnostic
                           "validation rejection has no reusable close-miss path"))))

let load_instantiation_seed ~derive ~env filename =
  match Episode.parse_file filename with
  | Error _ as failure -> failure
  | Ok episode -> (
      let target = Episode.target_value episode in
      match
        Evaluator.evaluate_instantiation_with_dangling_and_vdg ~derive env
          episode target
      with
      | Error _ as failure -> failure
      | Ok (result, coverage, graph) -> (
          match Evaluator.check_instantiation_oracle episode result with
          | Error error ->
              Option.iter clear_graph graph;
              Error error
          | Ok () -> (
              match result, coverage, graph with
              | (Phase.Instantiated _ | Phase.Trapped _ | Phase.Thrown _),
                Some coverage,
                Some graph ->
                  Ok
                    (reusable ~seed:(InstantiationSeed episode) ~target
                       ~coverage ~graph)
              | Phase.LinkingRejected (Phase.LinkOutcome _), Some _, Some graph ->
                  clear_graph graph;
                  Ok (Diagnostic "LinkO has no reusable close-miss path")
              | ( Phase.LinkingRejected (Phase.UnknownImport _)
                | Phase.TargetValidationRejected _ ),
                None,
                None ->
                  Ok (Diagnostic "instantiation preflight rejected the seed")
              | _ ->
                  Option.iter clear_graph graph;
                  error "candidate policy and seed VDG disagreed")))

let load_seed_with_vdg ~derive ~env ~phase filename =
  match phase with
  | Config.Validation -> load_validation_seed ~derive ~env filename
  | Config.Instantiation -> load_instantiation_seed ~derive ~env filename

let write_file path text =
  try
    let channel = open_out_bin path in
    Fun.protect
      ~finally:(fun () -> close_out_noerr channel)
      (fun () -> output_string channel text);
    Ok ()
  with Sys_error message -> error ("could not write candidate: " ^ message)

let render (observation : observation) seed mutated_module =
  match observation.semantic, seed, observation.category with
  | ValidationResult Phase.ValidationAccepted, ValidationSeed _,
    Some Policy.ValidationValid ->
      Renderer.render_validation ~mutated_module ~valid:true
      |> Result.map (fun text -> (text, None))
  | ValidationResult (Phase.ValidationRejected _), ValidationSeed _,
    Some Policy.ValidationInvalid ->
      Renderer.render_validation ~mutated_module ~valid:false
      |> Result.map (fun text -> (text, None))
  | InstantiationResult result, InstantiationSeed episode, Some category ->
      let rendering =
        match result, category with
        | Phase.Instantiated _, Policy.InitSuccess ->
            Some (Renderer.PlainInstantiation, None)
        | Phase.Trapped _, Policy.InitTrap ->
            Some (Renderer.AssertTrap, None)
        | Phase.Thrown { tagaddr; values; _ }, Policy.InitException ->
            Some (Renderer.RawException, Some (tagaddr, values))
        | Phase.LinkingRejected (Phase.LinkOutcome _), Policy.InitUnlinkable ->
            Some (Renderer.AssertUnlinkable, None)
        | _ -> None
      in
      (match rendering with
      | None -> error "typed result and output category disagreed"
      | Some (kind, metadata) ->
        Renderer.render_instantiation ~episode ~mutated_module ~kind
        |> Result.map (fun text -> (text, metadata)))
  | _ -> error "diagnostic or unsupported result cannot be rendered"

let category_of_observation (observation : observation) =
  match observation.category with
  | Some category -> Ok category
  | None -> error "diagnostic or unsupported result cannot be emitted"

let recheck env path = function
  | ValidationSeed _ -> (
      match Evaluator.parse_validation_file path with
      | Error _ as failure -> failure
      | Ok (root, expectation) -> (
          match Evaluator.evaluate_validation_with_dangling env root with
          | Error _ as failure -> failure
          | Ok (result, coverage) -> (
              match Evaluator.check_validation_expectation expectation result with
              | Error _ as failure -> failure
              | Ok () ->
                  let policy = Policy.of_validation_result result in
                  Ok
                    (observation (ValidationResult result) (Some coverage)
                       policy))))
  | InstantiationSeed _ -> (
      match Episode.parse_file path with
      | Error _ as failure -> failure
      | Ok episode -> (
          match
            Evaluator.evaluate_instantiation_with_dangling env episode
              (Episode.target_value episode)
          with
          | Error _ as failure -> failure
          | Ok (result, coverage) -> (
              match Evaluator.check_instantiation_oracle episode result with
              | Error _ as failure -> failure
              | Ok () ->
                  let policy = Policy.of_instantiation_result result in
                  Ok
                    (observation (InstantiationResult result) coverage policy))))

let coverage_preserves coverage selected_hits selected_close_misses =
  match coverage with
  | None -> IIdSet.is_empty selected_hits && IIdSet.is_empty selected_close_misses
  | Some coverage ->
      IIdSet.for_all (Single.is_hit coverage) selected_hits
      && IIdSet.for_all (Single.is_close_miss coverage) selected_close_misses

let render_and_recheck ~env ~seed ~mutated_module ~observation
    ~temporary_path ~selected_hits ~selected_close_misses =
  let cleanup () = ignore (Episode.remove_artifact temporary_path) in
  let transferred = ref false in
  cleanup ();
  Fun.protect
    ~finally:(fun () -> if not !transferred then cleanup ())
    (fun () ->
      match category_of_observation observation with
      | Error error ->
          Error error
      | Ok category -> (
          match render observation seed mutated_module with
          | Error error ->
              Error error
          | Ok (text, metadata) -> (
              match write_file temporary_path (text ^ "\n") with
              | Error error ->
                  Error error
              | Ok () ->
                  let metadata_result =
                    match metadata with
                    | None -> Ok ()
                    | Some (tagaddr, values) ->
                        Episode.write_exception_metadata temporary_path
                          ~tagaddr ~values
                  in
                  match metadata_result with
                  | Error error ->
                      Error error
                  | Ok () -> (
                      match recheck env temporary_path seed with
                      | Error error ->
                          Error error
                      | Ok replay -> (
                          match category_of_observation replay with
                          | Error error -> Error error
                          | Ok replay_category
                            when replay_category <> category ->
                              error
                                "rendered candidate changed its typed output category"
                          | Ok _
                            when not
                                   (coverage_preserves replay.coverage
                                      selected_hits selected_close_misses) ->
                              error
                                "rendered candidate did not preserve selected coverage"
                          | Ok _ ->
                              transferred := true;
                              Ok { category; coverage = replay.coverage })))))
