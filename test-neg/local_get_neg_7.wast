(assert_invalid
  (module (func $type-empty-vs-i32 (local i32) (local.get 0)))
  "type mismatch"
)
