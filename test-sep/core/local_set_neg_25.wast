(assert_invalid
  (module (func $type-empty-vs-i64 (param i64) (result i64) (local.set 0 (i64.const 1))))
  "type mismatch"
)
