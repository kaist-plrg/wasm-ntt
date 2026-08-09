(assert_invalid
  (module
    (table 1 funcref)
    (elem (i32.const 0) funcref (item (i32.const 0)))
  )
  "type mismatch"
)
