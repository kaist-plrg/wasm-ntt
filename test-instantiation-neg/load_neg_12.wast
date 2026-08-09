(assert_invalid
  (module (memory 1) (func $load32_u_i64 (i64.load32_u (i32.const 0))))
  "type mismatch"
)
