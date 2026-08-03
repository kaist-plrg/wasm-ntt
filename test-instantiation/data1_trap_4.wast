(assert_trap
  (module
    (memory 1)
    (memory 1)
    (memory 0)
    (data (memory 2) (i32.const 1))
  )
  "out of bounds memory access"
)
