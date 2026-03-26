(assert_invalid
  (module (memory i64 1) (func $load_f32 (f32.load (i64.const 0))))
  "type mismatch"
)
