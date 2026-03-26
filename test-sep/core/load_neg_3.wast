(assert_invalid
  (module (memory 1) (func $load8_u_i32 (i32.load8_u (i32.const 0))))
  "type mismatch"
)
