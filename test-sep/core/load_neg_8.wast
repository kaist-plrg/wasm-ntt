(assert_invalid
  (module (memory 1) (func $load8_u_i64 (i64.load8_u (i32.const 0))))
  "type mismatch"
)
