(assert_trap
  (module
    (memory 0)
    (data (i32.const 0) "a")
  )
  "out of bounds memory access"
)
