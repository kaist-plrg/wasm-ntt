(assert_invalid
  (module (func $type-local-num-vs-num (local f32) (i32.eqz (local.get 0))))
  "type mismatch"
)
