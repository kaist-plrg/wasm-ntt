(assert_invalid
  (module (memory 1) (func $load8_s_i64 (i64.load8_s (i32.const 0))))
  "type mismatch"
)
