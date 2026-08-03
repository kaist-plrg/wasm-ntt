module Multi = Coverage.Dangling.Multi
module Phase = Wasm_phase

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
  coverage : Multi.extension_policy option;
  emission : emission_policy;
}

let coverage hit_confidence record_close_misses =
  Some Multi.{ merge_hits = true; hit_confidence; record_close_misses }

let of_validation_result = function
  | Phase.ValidationAccepted ->
      { coverage = coverage Multi.Exact true;
        emission = MainArtifact ValidationValid }
  | Phase.ValidationRejected _ ->
      { coverage = coverage Multi.Likely false;
        emission = MainArtifact ValidationInvalid }

let of_instantiation_result = function
  | Phase.Instantiated _ ->
      { coverage = coverage Multi.Exact true; emission = MainArtifact InitSuccess }
  | Phase.Trapped _ ->
      { coverage = coverage Multi.Exact true; emission = MainArtifact InitTrap }
  | Phase.Thrown _ ->
      { coverage = coverage Multi.Exact true; emission = MainArtifact InitException }
  | Phase.LinkingRejected (Phase.LinkOutcome _) ->
      { coverage = coverage Multi.Exact false;
        emission = MainArtifact InitUnlinkable }
  | Phase.LinkingRejected (Phase.UnknownImport _)
  | Phase.TargetValidationRejected _ ->
      { coverage = None; emission = DiagnosticOnly }
