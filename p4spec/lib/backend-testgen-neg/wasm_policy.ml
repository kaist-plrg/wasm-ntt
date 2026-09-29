module Multi = Coverage.Dangling.Multi
module Phase = Wasm_phase

type output_category =
  | ValidationValid
  | ValidationInvalid
  | InitPass
  | InitFail
  | InvokeStuck
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

let of_invocation_result = function
  (* The invocation ran out of applicable rules: the outcome this phase looks
     for. Not a close-miss seed, since seeds are programs that return values. *)
  | Phase.InvokeStuck _ ->
      { coverage = coverage Multi.Exact false;
        emission = MainArtifact InvokeStuck }
  (* The invocation produced an outcome, so the specification was not stuck.
     Even a new dangling hit here only means a rule the interpreter backtracked
     out of, which is not what this phase reports. *)
  | Phase.InvokeReturned _ | Phase.InvokeTrapped _ ->
      { coverage = None; emission = DiagnosticOnly }
  (* Rendering an exception outcome needs the sidecar artifact pair that the
     instantiation phase uses; unsupported here. *)
  | Phase.InvokeThrown _ -> { coverage = None; emission = DiagnosticOnly }
  | Phase.TargetRejected _ -> { coverage = None; emission = DiagnosticOnly }
  | Phase.NotInvoked result -> (
      match result with
      | Phase.Instantiated _ ->
          (* Instantiated but the invocation never ran: a harness-level gap. *)
          { coverage = None; emission = DiagnosticOnly }
      | _ -> of_instantiation_result result)
