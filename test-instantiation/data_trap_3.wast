(assert_trap
  (module
    (memory 0 1)
    (data (i32.const 0) "a")
  )
  "out of bounds memory access"
)
