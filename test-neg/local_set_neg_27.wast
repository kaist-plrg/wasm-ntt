(assert_invalid
  (module (func $type-empty-vs-f64 (param f64) (result f64) (local.set 0 (f64.const 1))))
  "type mismatch"
)
