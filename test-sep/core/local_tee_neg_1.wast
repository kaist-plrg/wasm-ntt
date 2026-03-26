(assert_invalid
  (module (func $type-local-num-vs-num (result i64) (local i32) (local.tee 0 (i32.const 0))))
  "type mismatch"
)
