(assert_invalid
  (module (memory 1) (func $load16_u_i32 (i32.load16_u (i32.const 0))))
  "type mismatch"
)
