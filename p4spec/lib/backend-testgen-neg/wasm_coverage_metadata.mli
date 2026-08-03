type coverage_metadata = {
  schema : int;
  phase : Config.wasm_phase;
  coverage_relation : string;
  oracle : string;
}

val metadata_path : string -> string

val temporary_path : string -> string

val write :
  phase:Config.wasm_phase -> string -> (unit, Wasm_phase.phase_error) result

val validate :
  phase:Config.wasm_phase -> string -> (unit, Wasm_phase.phase_error) result
