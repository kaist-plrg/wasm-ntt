(assert_invalid
  (module
    (table 1 funcref)
    (elem (i32.ctz (i32.const 0)))
  )
  "constant expression required"
)
