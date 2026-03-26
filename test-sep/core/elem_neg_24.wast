(assert_invalid
  (module (table 1 funcref) (elem (i32.const 0) externref (ref.null extern)))
  "type mismatch"
)
