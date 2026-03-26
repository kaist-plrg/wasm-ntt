(assert_invalid
  (module (func $type-param-num-vs-num (param i32) (result i64) (local.get 0)))
  "type mismatch"
)
