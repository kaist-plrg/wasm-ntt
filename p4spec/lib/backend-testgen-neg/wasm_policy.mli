type output_category =
  | ValidationValid
  | ValidationInvalid
  | InitSuccess
  | InitTrap
  | InitException
  | InitUnlinkable
  | CloseMiss

type emission_policy =
  | MainArtifact of output_category
  | DiagnosticOnly
  | NoArtifact

type candidate_policy = {
  coverage : Coverage.Dangling.Multi.extension_policy option;
  emission : emission_policy;
}

val of_validation_result : Wasm_phase.validation_result -> candidate_policy

val of_instantiation_result : Wasm_phase.instantiation_result -> candidate_policy
