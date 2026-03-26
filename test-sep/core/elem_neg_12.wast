(assert_invalid
  (module
    (table 1 funcref)
    (elem (offset (nop) (i32.const 0)))
  )
  "constant expression required"
)
