(assert_invalid
  (module (func $type-local-num-vs-num (result f64) (local f64 i64) (f64.neg (local.get 1))))
  "type mismatch"
)
