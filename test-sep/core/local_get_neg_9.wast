(assert_invalid
  (module (func $type-empty-vs-f32 (local f32) (local.get 0)))
  "type mismatch"
)
