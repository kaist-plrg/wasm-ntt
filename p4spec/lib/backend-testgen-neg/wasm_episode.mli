module Script = Wasm_interpreter.Script
module Source = Wasm_interpreter.Source

type source_group = {
  ordinal : int;
  region : Source.region;
  raw_text : string;
  commands : Script.command list;
}

type t = {
  source_path : string;
  immutable_prefix : source_group list;
  target_module_var : Script.var option;
  target_entry : Wasm_interface.Script_harness.module_entry;
}

type invocation_episode = {
  invocation_source_path : string;
  invocation_prefix : source_group list;
  invocation_target_groups : source_group list;
  invocation_target_entry : Wasm_interface.Script_harness.module_entry;
  invocation_suffix : source_group list;
}

val parse_file : string -> (t, Wasm_phase.phase_error) result
val parse_observation_file :
  prefix_paths:string list -> string -> (t, Wasm_phase.phase_error) result
val parse_invocation_file :
  string -> (invocation_episode, Wasm_phase.phase_error) result
val copy_artifact :
  src_wast:string -> dst_wast:string -> (unit, Wasm_phase.phase_error) result
val move_artifact :
  src_wast:string -> dst_wast:string -> (unit, Wasm_phase.phase_error) result
val remove_artifact : string -> (unit, Wasm_phase.phase_error) result
val prefix_commands : t -> Script.command list
val target_module_var : t -> Script.var option
val target_value : t -> Lang.Il.value
val invocation_prefix_commands : invocation_episode -> Script.command list
val invocation_target_commands : invocation_episode -> Script.command list
val invocation_suffix_commands : invocation_episode -> Script.command list
val invocation_target_value : invocation_episode -> Lang.Il.value
val mutation_root : Lang.Il.value -> Lang.Il.value
val module_entry_of_value :
  Lang.Il.value ->
  (Wasm_interface.Script_harness.module_entry, Wasm_phase.phase_error) result
val prepare :
  Wasm_interface.Script_harness.runtime ->
  t ->
  Lang.Il.value ->
  ((Wasm_interface.Script_harness.state *
    Wasm_interface.Script_harness.module_entry),
   Wasm_phase.phase_error)
  result
