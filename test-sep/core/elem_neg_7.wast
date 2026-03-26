(assert_invalid
  (module
    (table 1 funcref)
    (elem (offset (i32.const 0) (i32.const 0)))
  )
  "type mismatch"
)
