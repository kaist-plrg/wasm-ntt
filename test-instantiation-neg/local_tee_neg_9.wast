(assert_invalid
  (module (func $type-param-num-vs-num (param f32) (i32.eqz (local.get 0))))
  "type mismatch"
)
