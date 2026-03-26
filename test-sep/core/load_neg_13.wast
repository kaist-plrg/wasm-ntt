(assert_invalid
  (module (memory 1) (func $load_f32 (f32.load (i32.const 0))))
  "type mismatch"
)
