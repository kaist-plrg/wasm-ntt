(assert_invalid
  (module (memory 1) (func $load_i64 (i64.load (i32.const 0))))
  "type mismatch"
)
