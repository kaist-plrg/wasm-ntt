open Lang.Il
open Util.Source

module Harness = Wasm_interface.Script_harness

type relation_failure = {
  relation : string;
  at : region;
  message : string;
}

type linking_failure =
  | UnknownImport of { message : string }
  | LinkOutcome of { store : value }

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
  | TargetValidationRejected of relation_failure
  | LinkingRejected of linking_failure

type phase_error =
  | SyntaxError of region * string
  | EpisodeError of region * string
  | RelationFailure of relation_failure
  | HarnessFailure of region * string
  | UnsupportedOutcome of string
  | CoverageMetadataError of string

type 'a evaluation = ('a, phase_error) result

let instantiation_result_of_outputs ?(at = no_region) outputs =
  try
    match Harness.init_outputs at outputs with
    | Harness.LinkFailed store -> Ok (LinkingRejected (LinkOutcome { store }))
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
            Ok (Thrown { module_inst; store; tagaddr; values })
        | Harness.Exhausted _ -> Error (UnsupportedOutcome "ExhaustionO"))
  with
  | Util.Error.InterpError (error_at, message) ->
      Error (HarnessFailure (error_at, message))
