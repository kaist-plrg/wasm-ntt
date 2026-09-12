(assert_invalid
  (module (memory i64 1) (func $load8_s_i32 (i32.load8_s (i64.const 0))))
  "type mismatch"
)
