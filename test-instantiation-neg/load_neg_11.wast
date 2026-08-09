(assert_invalid
  (module (memory 1) (func $load32_s_i64 (i64.load32_s (i32.const 0))))
  "type mismatch"
)
