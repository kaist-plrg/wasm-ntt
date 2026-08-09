(assert_invalid
  (module (func $type-param-arg-num-vs-num (param i32) (local.tee 0 (f32.const 0))))
  "type mismatch"
)
