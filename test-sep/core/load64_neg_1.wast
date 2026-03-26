(assert_invalid
  (module (memory i64 1) (func $load_i32 (i32.load (i64.const 0))))
  "type mismatch"
)
