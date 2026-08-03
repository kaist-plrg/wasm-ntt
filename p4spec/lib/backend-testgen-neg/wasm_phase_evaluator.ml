open Util.Error
open Util.Source

module Episode = Wasm_episode
module Harness = Wasm_interface.Script_harness
module Phase = Wasm_phase
module Sim = Runtime.Sim.Signature
module DCov = Coverage.Dangling.Single
module Dep = Runtime.Testgen_neg.Dep

type env = {
  simulator : (module Sim.SIM);
  spec : Sim.spec;
  runtime : Harness.runtime;
}

let make_env ~simulator ~spec =
  { simulator; spec; runtime = Harness.{ simulator } }

let util_region (region : Wasm_interpreter.Source.region) =
  let pos (position : Wasm_interpreter.Source.pos) =
    { file = position.file; line = position.line; column = position.column }
  in
  { left = pos region.left; right = pos region.right }

let parse_validation_file filename =
  try Ok (Wasm_interface.Parse.parse_file filename) with
  | Wasm_interpreter.Parse.Syntax (region, message)
  | Wasm_interpreter.Decode.Code (region, message)
  | Wasm_interpreter.Custom.Syntax (region, message) ->
      Error (Phase.SyntaxError (util_region region, message))

let validation_category = function
  | Phase.ValidationAccepted -> "validation accepted"
  | Phase.ValidationRejected _ -> "validation rejected"

let check_validation_expectation expectation result =
  let matches =
    match (expectation, result) with
    | Wasm_interface.Parse.Positive, Phase.ValidationAccepted
    | Wasm_interface.Parse.Negative, Phase.ValidationRejected _ -> true
    | _ -> false
  in
  if matches then Ok ()
  else
    let expected =
      match expectation with
      | Wasm_interface.Parse.Positive -> "validation accepted"
      | Wasm_interface.Parse.Negative -> "validation rejected"
    in
    Error
      (Phase.EpisodeError
         ( no_region,
           "validation expectation mismatch: expected " ^ expected ^ ", got "
           ^ validation_category result ))

let instantiation_category = function
  | Phase.Instantiated _ -> "instantiated"
  | Phase.Trapped _ -> "trapped"
  | Phase.Thrown _ -> "thrown"
  | Phase.TargetValidationRejected _ -> "target validation rejected"
  | Phase.LinkingRejected _ -> "linking rejected"

let check_instantiation_oracle episode result =
  let expected = episode.Episode.expected_outcome in
  let matches =
    match (expected, result) with
    | Episode.ExpectNormalInstantiation, Phase.Instantiated _
    | Episode.ExpectTrap, Phase.Trapped _
    | Episode.ExpectLink, Phase.LinkingRejected _
    | Episode.ExpectRawException, Phase.Thrown _ -> true
    | _ -> false
  in
  if matches then Ok ()
  else
    let expected =
      match expected with
      | Episode.ExpectNormalInstantiation -> "instantiated"
      | Episode.ExpectTrap -> "trapped"
      | Episode.ExpectLink -> "linking rejected"
      | Episode.ExpectRawException -> "thrown"
    in
    Error
      (Phase.EpisodeError
         ( Episode.target_driver_region episode,
           "instantiation oracle mismatch: expected " ^ expected ^ ", got "
           ^ instantiation_category result ))

let classify_validation (relation_result : Sim.rel_result) coverage graph =
  match relation_result with
  | Pass _ -> Ok (Phase.ValidationAccepted, coverage, graph)
  | Fail (at, message) ->
      Ok
        ( Phase.ValidationRejected
            { relation = "Modules_ok"; at; message },
          coverage,
          graph )

let evaluate_validation_with_dangling env module_list =
  try
    let result, coverage =
      Runner.eval_rel_with_dangling ~simulator:env.simulator ~spec:env.spec
        ~root:module_list ~relname:"Modules_ok" ~inputs:[ module_list ]
    in
    classify_validation result coverage ()
    |> Result.map (fun (result, coverage, ()) -> (result, coverage))
  with
  | InterpError (at, message) -> Error (Phase.HarnessFailure (at, message))

let evaluate_validation_with_dangling_and_vdg ~derive env module_list =
  try
    let result, coverage, graph =
      Runner.eval_rel_with_dangling_and_vdg ~derive
        ~simulator:env.simulator ~spec:env.spec ~root:module_list
        ~relname:"Modules_ok" ~inputs:[ module_list ]
    in
    classify_validation result coverage graph
  with
  | InterpError (at, message) -> Error (Phase.HarnessFailure (at, message))

type init_observation = {
  relation_result : Sim.rel_result;
  coverage : DCov.t;
  graph : Dep.Graph.t option;
}

let evaluate_instantiation_common ~run_init env episode mutated_target =
  try
    match Episode.prepare env.runtime episode mutated_target with
    | Error _ as error -> error
    | Ok (state, target_entry) ->
        let module Simulator = (val env.simulator : Sim.SIM) in
        (match Simulator.Interp.eval_rel "Module_ok" [ target_entry.value ] with
        | Fail (at, message) ->
            Ok
              ( Phase.TargetValidationRejected
                  { relation = "Module_ok"; at; message },
                None,
                None )
        | Pass _ -> (
            match Harness.resolve_imports no_region state target_entry.module_ with
            | Error (Harness.UnknownImport message) ->
                Ok (Phase.LinkingRejected (Phase.UnknownImport { message }), None, None)
            | Ok externaddrs ->
                let inputs =
                  [ state.Harness.store;
                    target_entry.Harness.value;
                    Harness.externaddr_list externaddrs ]
                in
                let observation =
                  run_init ~root:(Episode.mutation_root mutated_target) ~inputs
                in
                match observation.relation_result with
                | Fail (at, message) ->
                    Error
                      (Phase.RelationFailure
                         { relation = "Init_with_store_ok"; at; message })
                | Pass outputs ->
                    Result.map
                      (fun result ->
                        (result, Some observation.coverage, observation.graph))
                      (Phase.instantiation_result_of_outputs ~at:no_region outputs)))
  with
  | InterpError (at, message) -> Error (Phase.HarnessFailure (at, message))

let evaluate_instantiation_with_dangling env episode mutated_target =
  let run_init ~root ~inputs =
    let relation_result, coverage =
      Runner.eval_rel_with_dangling ~simulator:env.simulator ~spec:env.spec
        ~root ~relname:"Init_with_store_ok" ~inputs
    in
    { relation_result; coverage; graph = None }
  in
  Result.map
    (fun (result, coverage, _) -> (result, coverage))
    (evaluate_instantiation_common ~run_init env episode mutated_target)

let evaluate_instantiation_with_dangling_and_vdg ~derive env episode mutated_target =
  let run_init ~root ~inputs =
    let relation_result, coverage, graph =
      Runner.eval_rel_with_dangling_and_vdg ~derive ~simulator:env.simulator
        ~spec:env.spec ~root ~relname:"Init_with_store_ok" ~inputs
    in
    { relation_result; coverage; graph = Some graph }
  in
  evaluate_instantiation_common ~run_init env episode mutated_target
