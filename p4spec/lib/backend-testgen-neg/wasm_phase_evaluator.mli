module Sim = Runtime.Sim.Signature

type env = {
  simulator : (module Sim.SIM);
  spec : Sim.spec;
  runtime : Wasm_interface.Script_harness.runtime;
}

val make_env : simulator:(module Sim.SIM) -> spec:Sim.spec -> env

val parse_validation_file :
  string ->
  ((Lang.Il.value * Wasm_interface.Parse.expectation), Wasm_phase.phase_error)
  result

val evaluate_validation_with_dangling :
  env ->
  Lang.Il.value ->
  (Wasm_phase.validation_result * Coverage.Dangling.Single.t, Wasm_phase.phase_error)
  result

val evaluate_validation_with_dangling_and_vdg :
  derive:bool ->
  env ->
  Lang.Il.value ->
  (Wasm_phase.validation_result * Coverage.Dangling.Single.t *
   Runtime.Testgen_neg.Dep.Graph.t,
   Wasm_phase.phase_error)
  result

val evaluate_instantiation_with_dangling :
  env ->
  Wasm_episode.t ->
  Lang.Il.value ->
  ( Wasm_phase.instantiation_result * Coverage.Dangling.Single.t option,
    Wasm_phase.phase_error )
  result

val evaluate_instantiation_with_dangling_and_vdg :
  derive:bool ->
  env ->
  Wasm_episode.t ->
  Lang.Il.value ->
  ( Wasm_phase.instantiation_result * Coverage.Dangling.Single.t option *
    Runtime.Testgen_neg.Dep.Graph.t option,
    Wasm_phase.phase_error )
  result

val check_validation_expectation :
  Wasm_interface.Parse.expectation ->
  Wasm_phase.validation_result ->
  (unit, Wasm_phase.phase_error) result

val check_instantiation_oracle :
  Wasm_episode.t ->
  Wasm_phase.instantiation_result ->
  (unit, Wasm_phase.phase_error) result
