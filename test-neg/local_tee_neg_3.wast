(assert_invalid
  (module (func $type-local-num-vs-num (local f64 i64) (f64.neg (local.tee 1 (i64.const 0)))))
  "type mismatch"
)
