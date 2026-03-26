(assert_invalid
  (module (memory 1) (func $load16_s_i32 (i32.load16_s (i32.const 0))))
  "type mismatch"
)
