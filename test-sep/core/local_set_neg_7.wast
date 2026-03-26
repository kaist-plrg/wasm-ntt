(assert_invalid
  (module (func $type-param-arg-num-vs-num (param f32) (local.set 0 (f64.const 0))))
  "type mismatch"
)
