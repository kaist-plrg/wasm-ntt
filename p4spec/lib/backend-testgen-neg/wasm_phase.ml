open Lang.Il
open Util.Source

module Harness = Wasm_interface.Script_harness

type relation_failure = {
  relation : string;
  at : region;
  message : string;
}

type validation_result =
  | ValidationAccepted
  | ValidationRejected of relation_failure

type instantiation_result =
  | Instantiated of {
      module_inst : value;
      store : value;
    }
  | Trapped of {
      module_inst : value;
      store : value;
    }
  | Thrown of {
      module_inst : value;
      store : value;
      tagaddr : value;
      values : value list;
    }
  | InitRelationFailed of relation_failure
  | ImportResolutionFailed of { message : string }

(* Invocation instantiates its target before invoking it, so the invocation may
   never happen; [NotInvoked] carries whatever stopped it.

   [InvokeStuck] is what this phase hunts for: under a specification whose trap
   counterparts have been removed, going out of bounds leaves the execution
   relation with no applicable rule. *)
type invocation_result =
  | InvokeReturned of {
      store : value;
      values : value list;
    }
  | InvokeTrapped of { store : value }
  | InvokeThrown of {
      store : value;
      tagaddr : value;
      values : value list;
    }
  | InvokeStuck of relation_failure
  (* The oracle only counts a stuck invocation of a module the type system
     accepts, so a rejected target never reaches the invocation. *)
  | TargetRejected of relation_failure
  | NotInvoked of instantiation_result

type phase_error =
  | SyntaxError of region * string
  | EpisodeError of region * string
  | HarnessFailure of region * string
  | CoverageMetadataError of string

type 'a evaluation = ('a, phase_error) result

let instantiation_result_of_outputs ?(at = no_region) outputs =
  try
    match Harness.init_outputs at outputs with
    | Harness.InitExecuted { module_inst; outcome } -> (
        match outcome with
        | Harness.Returned { store; values = [] } ->
            Ok (Instantiated { module_inst; store })
        | Harness.Returned _ ->
            Error
              (HarnessFailure
                 (at, "Init_with_store_ok ValuesO returned values"))
        | Harness.Trapped store -> Ok (Trapped { module_inst; store })
        | Harness.Thrown { store; tagaddr; values } ->
            Ok (Thrown { module_inst; store; tagaddr; values }))
  with
  | Util.Error.InterpError (error_at, message) ->
      Error (HarnessFailure (error_at, message))

let invocation_result_of_outputs ?(at = no_region) outputs =
  try
    match Harness.invoke_outputs at outputs with
    | Harness.Returned { store; values } -> Ok (InvokeReturned { store; values })
    | Harness.Trapped store -> Ok (InvokeTrapped { store })
    | Harness.Thrown { store; tagaddr; values } ->
        Ok (InvokeThrown { store; tagaddr; values })
  with
  | Util.Error.InterpError (error_at, message) ->
      Error (HarnessFailure (error_at, message))
