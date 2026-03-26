(assert_invalid
  (module (memory i64 1) (func $load16_s_i64 (i64.load16_s (i64.const 0))))
  "type mismatch"
)
