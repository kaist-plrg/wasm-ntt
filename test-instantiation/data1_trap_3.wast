(assert_trap
  (module
    (memory 1 1)
    (memory 0 1)
    (memory 1 1)
    (data (memory 1) (i32.const 0) "a")
  )
  "out of bounds memory access"
)
