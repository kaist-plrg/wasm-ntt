(assert_invalid
  (module (func $type-local-num-vs-num (result i64) (local i32) (local.get 0)))
  "type mismatch"
)
