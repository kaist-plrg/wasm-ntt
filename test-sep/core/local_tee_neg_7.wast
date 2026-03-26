(assert_invalid
  (module (func $type-local-arg-num-vs-num (local f64 i64) (local.tee 1 (f64.const 0))))
  "type mismatch"
)
