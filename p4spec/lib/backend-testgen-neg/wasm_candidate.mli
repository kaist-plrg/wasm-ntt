module Single = Coverage.Dangling.Single
module Dep = Runtime.Testgen_neg.Dep

type seed =
  | ValidationSeed of Wasm_interface.Parse.expectation
  | InstantiationSeed of Wasm_episode.t

type semantic_result =
  | ValidationResult of Wasm_phase.validation_result
  | InstantiationResult of Wasm_phase.instantiation_result

type observation = {
  semantic : semantic_result;
  coverage : Single.t option;
  policy : Wasm_policy.candidate_policy;
  category : Wasm_policy.output_category option;
  emission : Wasm_policy.emission_policy;
}

type loaded_seed = {
  seed : seed;
  target : Lang.Il.value;
  root : Lang.Il.value;
  coverage : Single.t;
  graph : Dep.Graph.t;
  sources : Domain.Lib.VIdSet.t;
}

type seed_load = Reusable of loaded_seed | Diagnostic of string

type verified = {
  category : Wasm_policy.output_category;
  coverage : Single.t option;
}

type mutation_provenance = {
  intended_iid : int;
  source_vid : int;
  depth : int option;
  mutation : string;
  source : string;
  mutated : string;
}

val single_module_of_root :
  Lang.Il.value -> (Lang.Il.value, Wasm_phase.phase_error) result

val random_source_vids :
  limit:int -> Domain.Lib.VIdSet.t -> int list

val filter_derivations :
  Domain.Lib.VIdSet.t ->
  (int * int) list ->
  (int * int) list

val select_hits :
  covermode:Modes.covermode ->
  intended:int ->
  Domain.Lib.IIdSet.t ->
  Domain.Lib.IIdSet.t

val evaluate :
  Wasm_phase_evaluator.env ->
  seed ->
  Lang.Il.value ->
  (observation, Wasm_phase.phase_error) result

val load_seed_with_vdg :
  derive:bool ->
  env:Wasm_phase_evaluator.env ->
  phase:Config.wasm_phase ->
  string ->
  (seed_load, Wasm_phase.phase_error) result

val decorate_artifact :
  provenance:mutation_provenance ->
  selected_hits:Domain.Lib.IIdSet.t ->
  selected_close_misses:Domain.Lib.IIdSet.t ->
  string ->
  (string, Wasm_phase.phase_error) result

val render_and_recheck :
  env:Wasm_phase_evaluator.env ->
  seed:seed ->
  mutated_module:Lang.Il.value ->
  observation:observation ->
  provenance:mutation_provenance ->
  temporary_path:string ->
  selected_hits:Domain.Lib.IIdSet.t ->
  selected_close_misses:Domain.Lib.IIdSet.t ->
  (verified, Wasm_phase.phase_error) result
