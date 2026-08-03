(assert_trap
  (module
    (memory 0 1)
    (data (i32.const 1))
  )
  "out of bounds memory access"
)
