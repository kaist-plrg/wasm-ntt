type render_kind =
  | PlainInstantiation
  | AssertTrap
  | AssertUnlinkable
  | RawException

val render_validation :
  mutated_module:Lang.Il.value ->
  valid:bool ->
  (string, Wasm_phase.phase_error) result

val render_instantiation :
  episode:Wasm_episode.t ->
  mutated_module:Lang.Il.value ->
  kind:render_kind ->
  (string, Wasm_phase.phase_error) result
