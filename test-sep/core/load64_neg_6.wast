(assert_invalid
  (module (memory i64 1) (func $load_i64 (i64.load (i64.const 0))))
  "type mismatch"
)
