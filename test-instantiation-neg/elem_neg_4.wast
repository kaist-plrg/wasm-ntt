(assert_invalid
  (module
    (table 1 funcref)
    (elem (i64.const 0))
  )
  "type mismatch"
)
