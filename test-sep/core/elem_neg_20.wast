(assert_invalid
  (module
    (table 1 funcref)
    (elem (i32.const 0) funcref (i32.const 0))
  )
  "type mismatch"
)
