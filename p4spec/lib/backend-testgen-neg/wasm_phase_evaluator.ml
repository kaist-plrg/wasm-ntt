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

type invocation_observation = {
  command_index : int;
  relation : string;
  coverage : DCov.t;
}

let evaluate_instantiation_common ~run_init env episode mutated_target =
  try
    match Episode.prepare env.runtime episode mutated_target with
    | Error _ as error -> error
    | Ok (state, target_entry) ->
        (match Harness.resolve_imports no_region state target_entry.module_ with
        | Error (Harness.UnknownImport message) ->
            Ok (Phase.ImportResolutionFailed { message }, None, None)
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
                Ok
                  ( Phase.InitRelationFailed
                      { relation = "Init_with_store_ok"; at; message },
                    Some observation.coverage,
                    observation.graph )
            | Pass outputs ->
                Result.map
                  (fun result ->
                    (result, Some observation.coverage, observation.graph))
                  (Phase.instantiation_result_of_outputs ~at:no_region outputs))
  with
  | InterpError (at, message) -> Error (Phase.HarnessFailure (at, message))
  | Z.Overflow ->
      Error
        (Phase.HarnessFailure
           (no_region, "integer conversion overflow during Init_with_store_ok"))

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

(* Coverage and the dependency graph have different boundaries here. Only the
   observed invocation is measured, but the graph must span instantiation and
   every replayed invocation: a close miss in the observed one backtracks to the
   module through state an earlier invocation changed. *)
let evaluate_invocation_with_dangling_and_vdg ?(vdg = true) ~derive env
    (episode : Episode.invocation_episode) mutated_target =
  try
    match Episode.prepare_invocation env.runtime episode mutated_target with
    | Error _ as error -> error
    | Ok (state, target_entry) -> (
        let root = Episode.mutation_root mutated_target in
        let outcome =
          Runner.with_vdg_session ~vdg ~derive ~simulator:env.simulator
            ~spec:env.spec ~root (fun session ->
              let stuck = ref None in
              let observed = ref None in
              let eval_relation ~relname inputs =
                if
                  String.equal relname "Init_with_store_ok"
                  || String.equal relname "Invoke"
                then
                  match session.Runner.step ~relname ~inputs with
                  | Pass outputs ->
                      if String.equal relname "Invoke" then
                        observed := Some outputs;
                      outputs
                  | Fail (at, message) ->
                      stuck := Some { Phase.relation = relname; at; message };
                      error_interp at (relname ^ " has no applicable rule")
                else Harness.eval_dynamic_rel env.runtime relname inputs
              in
              let run state commands =
                Harness.run_commands ~eval_relation env.runtime state commands
              in
              let result =
                try
                  session.Runner.set_coverage_enabled false;
                  let state =
                    run state (Episode.invocation_driver_commands episode)
                  in
                  let state =
                    run state (Episode.invocation_replayed_commands episode)
                  in
                  session.Runner.set_coverage_enabled true;
                  ignore
                    (run state (Episode.invocation_observed_commands episode));
                  match !observed with
                  | Some outputs -> Phase.invocation_result_of_outputs outputs
                  | None ->
                      Ok
                        (Phase.NotInvoked
                           (Phase.InitRelationFailed
                              { relation = "Invoke";
                                at = no_region;
                                message = "no invocation was observed" }))
                with
                | InterpError (at, message) -> (
                    match !stuck with
                    | Some failure -> Ok (Phase.InvokeStuck failure)
                    | None -> Error (Phase.HarnessFailure (at, message)))
              in
              Result.map
                (fun result ->
                  (result, Some (session.Runner.read_coverage ()),
                   session.Runner.graph))
                result)
        in
        (* The validation gate runs only for a stuck invocation. It is a whole
           extra pass over the module, and almost no candidate gets stuck, so
           asking first would dominate the campaign. *)
        match outcome with
        | Ok (Phase.InvokeStuck _, _, _) -> (
            let validation, _ =
              Runner.eval_rel_with_dangling ~simulator:env.simulator
                ~spec:env.spec ~root:target_entry.Harness.value
                ~relname:"Module_ok" ~inputs:[ target_entry.Harness.value ]
            in
            match validation with
            | Fail (at, message) ->
                Ok
                  ( Phase.TargetRejected
                      { relation = "Module_ok"; at; message },
                    None,
                    None )
            | Pass _ -> outcome)
        | _ -> outcome)
  with
  | InterpError (at, message) -> Error (Phase.HarnessFailure (at, message))
  | Z.Overflow ->
      Error
        (Phase.HarnessFailure
           (no_region, "integer conversion overflow during invocation"))

let observe_invocation_with_dangling env
    (episode : Episode.invocation_episode) ~on_observation =
  if Inst.Hook.is_active () then
    Error
      (Phase.HarnessFailure
         (no_region, "instrumentation handler leaked from an earlier run"))
  else (
    Wasm_interface.Builtin_hooks.init ();
    try
      let state =
        Harness.run_commands env.runtime (Harness.initial_state ())
          (Episode.invocation_prefix_commands episode)
      in
      let root =
        Episode.mutation_root (Episode.invocation_target_value episode)
      in
      let run_group state (group : Episode.source_group) =
        let observations = ref [] in
        let eval_relation ~relname inputs =
          if
            String.equal relname "Init_with_store_ok"
            || String.equal relname "Invoke"
          then
            let relation_result, coverage =
              Runner.eval_rel_with_dangling ~simulator:env.simulator
                ~spec:env.spec ~root ~relname ~inputs
            in
            match relation_result with
            | Pass outputs ->
                observations :=
                  { command_index = group.ordinal + 1; relation = relname; coverage }
                  :: !observations;
                outputs
            | Fail (at, message) ->
                error_interp at (relname ^ " failed: " ^ message)
          else Harness.eval_dynamic_rel env.runtime relname inputs
        in
        let state =
          Harness.run_commands ~eval_relation env.runtime state group.commands
        in
        List.rev !observations |> List.iter on_observation;
        state
      in
      let state =
        List.fold_left run_group state episode.invocation_target_groups
      in
      ignore (List.fold_left run_group state episode.invocation_suffix);
      Ok ()
    with
    | InterpError (at, message) ->
        Error (Phase.HarnessFailure (at, message))
    | Z.Overflow ->
        Error
          (Phase.HarnessFailure
             (no_region, "integer conversion overflow during invocation boot")))
