(assert_invalid
  (module (memory 1) (func $load16_s_i64 (i64.load16_s (i32.const 0))))
  "type mismatch"
)
