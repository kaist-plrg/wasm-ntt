(assert_trap
  (module
    (table 0 1 funcref)
    (func $f)
    (elem (i32.const 0) $f)
  )
  "out of bounds table access"
)
