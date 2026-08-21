type coverage_metadata = {
  schema : int;
  phase : Config.wasm_phase;
  coverage_relations : string list;
  oracle : string;
}

val metadata_path : string -> string
val temporary_path : string -> string

val write :
  ?coverage_relations:string list ->
  phase:Config.wasm_phase ->
  string ->
  (unit, Wasm_phase.phase_error) result

val validate :
  phase:Config.wasm_phase -> string -> (unit, Wasm_phase.phase_error) result

val read :
  phase:Config.wasm_phase ->
  string ->
  (coverage_metadata, Wasm_phase.phase_error) result
