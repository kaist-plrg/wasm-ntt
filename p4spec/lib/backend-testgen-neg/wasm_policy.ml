module Multi = Coverage.Dangling.Multi
module Phase = Wasm_phase

type output_category =
  | ValidationValid
  | ValidationInvalid
  | InitPass
  | InitFail
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
  | Phase.Instantiated _ | Phase.Trapped _ | Phase.Thrown _ ->
      { coverage = coverage Multi.Exact true; emission = MainArtifact InitPass }
  | Phase.InitRelationFailed _ ->
      { coverage = coverage Multi.Likely false; emission = MainArtifact InitFail }
  | Phase.ImportResolutionFailed _ ->
      { coverage = None; emission = DiagnosticOnly }
