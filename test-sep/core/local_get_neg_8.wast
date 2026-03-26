(assert_invalid
  (module (func $type-empty-vs-i64 (local i64) (local.get 0)))
  "type mismatch"
)
