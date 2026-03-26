(assert_invalid
  (module (func $type-mixed-arg-num-vs-num (param i64) (local f64 i64) (local.set 1 (i64.const 0))))
  "type mismatch"
)
