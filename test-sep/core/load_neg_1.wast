(assert_invalid
  (module (memory 1) (func $load_i32 (i32.load (i32.const 0))))
  "type mismatch"
)
