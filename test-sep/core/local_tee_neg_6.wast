(assert_invalid
  (module (func $type-local-arg-num-vs-num (local f32) (local.tee 0 (f64.const 0))))
  "type mismatch"
)
