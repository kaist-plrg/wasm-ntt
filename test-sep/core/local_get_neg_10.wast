(assert_invalid
  (module (func $type-empty-vs-f64 (local f64) (local.get 0)))
  "type mismatch"
)
