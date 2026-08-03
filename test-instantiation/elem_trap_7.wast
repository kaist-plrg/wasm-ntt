(assert_trap
  (module
    (table 10 20 funcref)
    (func $f)
    (elem (i32.const 10) $f)
  )
  "out of bounds table access"
)
