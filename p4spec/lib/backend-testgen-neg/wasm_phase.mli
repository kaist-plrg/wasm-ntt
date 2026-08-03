type relation_failure = {
  relation : string;
  at : Util.Source.region;
  message : string;
}

type linking_failure =
  | UnknownImport of { message : string }
  | LinkOutcome of { store : Lang.Il.value }

type validation_result =
  | ValidationAccepted
  | ValidationRejected of relation_failure

type instantiation_result =
  | Instantiated of {
      module_inst : Lang.Il.value;
      store : Lang.Il.value;
    }
  | Trapped of {
      module_inst : Lang.Il.value;
      store : Lang.Il.value;
    }
  | Thrown of {
      module_inst : Lang.Il.value;
      store : Lang.Il.value;
      tagaddr : Lang.Il.value;
      values : Lang.Il.value list;
    }
  | TargetValidationRejected of relation_failure
  | LinkingRejected of linking_failure

type phase_error =
  | SyntaxError of Util.Source.region * string
  | EpisodeError of Util.Source.region * string
  | RelationFailure of relation_failure
  | HarnessFailure of Util.Source.region * string
  | UnsupportedOutcome of string
  | CoverageMetadataError of string

type 'a evaluation = ('a, phase_error) result

val instantiation_result_of_outputs :
  ?at:Util.Source.region ->
  Lang.Il.value list ->
  (instantiation_result, phase_error) result
