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

val parse_file : string -> (t, Wasm_phase.phase_error) result
val parse_observation_file :
  prefix_paths:string list -> string -> (t, Wasm_phase.phase_error) result
val copy_artifact :
  src_wast:string -> dst_wast:string -> (unit, Wasm_phase.phase_error) result
val move_artifact :
  src_wast:string -> dst_wast:string -> (unit, Wasm_phase.phase_error) result
val remove_artifact : string -> (unit, Wasm_phase.phase_error) result
val prefix_commands : t -> Script.command list
val target_module_var : t -> Script.var option
val target_value : t -> Lang.Il.value
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
