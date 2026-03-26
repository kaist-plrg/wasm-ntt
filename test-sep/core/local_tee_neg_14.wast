(assert_invalid
  (module (func $type-param-arg-num-vs-num (param f64 i64) (local.tee 1 (f64.const 0))))
  "type mismatch"
)
