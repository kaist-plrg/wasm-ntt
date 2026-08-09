(assert_invalid
  (module (table 1 (ref null func) (i32.const 0)))
  "type mismatch"
)
