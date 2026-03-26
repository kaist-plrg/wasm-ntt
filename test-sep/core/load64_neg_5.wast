(assert_invalid
  (module (memory i64 1) (func $load16_u_i32 (i32.load16_u (i64.const 0))))
  "type mismatch"
)
