(assert_trap
  (module
    (memory 1 1)
    (memory 1 1)
    (memory 0 0)
    (data (memory 2) (i32.const 0) "a")
  )
  "out of bounds memory access"
)
