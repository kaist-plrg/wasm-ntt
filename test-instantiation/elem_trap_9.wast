(assert_trap
  (module
    (table 10 funcref)
    (func $f)
    (elem (i32.const -1) $f)
  )
  "out of bounds table access"
)
