(assert_invalid
  (module (memory i64 1) (func $load32_u_i64 (i64.load32_u (i64.const 0))))
  "type mismatch"
)
