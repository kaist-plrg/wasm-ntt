(assert_invalid
  (module (memory i64 1) (func $load_f64 (f64.load (i64.const 0))))
  "type mismatch"
)
