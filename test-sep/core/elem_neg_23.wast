(assert_invalid
  (module (func $f) (table 1 externref) (elem (i32.const 0) $f))
  "type mismatch"
)
