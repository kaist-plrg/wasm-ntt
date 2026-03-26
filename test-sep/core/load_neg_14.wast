(assert_invalid
  (module (memory 1) (func $load_f64 (f64.load (i32.const 0))))
  "type mismatch"
)
