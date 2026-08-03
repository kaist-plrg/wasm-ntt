module Script = Wasm_interpreter.Script
module Source = Wasm_interpreter.Source

type driver_kind =
  | PlainInstance
  | ExplicitInstance
  | ModuleTrapAssertion
  | ModuleUnlinkableAssertion

type target_driver = {
  kind : driver_kind;
  command : Script.command;
  instance_var : Script.var option;
  module_var : Script.var option;
}

type expected_driver_outcome =
  | ExpectNormalInstantiation
  | ExpectTrap
  | ExpectLink
  | ExpectRawException

type source_group = {
  ordinal : int;
  region : Source.region;
  raw_text : string;
  commands : Script.command list;
}

type target_layout =
  | SugaredInOneGroup of {
      group : source_group;
      module_command : Script.command;
      driver : target_driver;
    }
  | ExplicitAcrossGroups of {
      definition_group : source_group;
      module_command : Script.command;
      driver_group : source_group;
      driver : target_driver;
    }

type t = {
  source_path : string;
  immutable_prefix : source_group list;
  target_layout : target_layout;
  target_entry : Wasm_interface.Script_harness.module_entry;
  expected_outcome : expected_driver_outcome;
}

type exception_metadata = {
  tagaddr : string;
  values : string list;
}

val parse_file : string -> (t, Wasm_phase.phase_error) result
val exception_metadata_path : string -> string
val write_exception_metadata :
  string ->
  tagaddr:Lang.Il.value ->
  values:Lang.Il.value list ->
  (unit, Wasm_phase.phase_error) result
val read_exception_metadata :
  string -> (exception_metadata, Wasm_phase.phase_error) result
val copy_artifact :
  src_wast:string -> dst_wast:string -> (unit, Wasm_phase.phase_error) result
val move_artifact :
  src_wast:string -> dst_wast:string -> (unit, Wasm_phase.phase_error) result
val remove_artifact : string -> (unit, Wasm_phase.phase_error) result
val prefix_commands : t -> Script.command list
val target_module_var : t -> Script.var option
val target_driver : t -> target_driver
val target_driver_region : t -> Util.Source.region
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
