(assert_trap
  (module
    (table 0 funcref)
    (elem (i32.const 1))
  )
  "out of bounds table access"
)
