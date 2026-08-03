(assert_trap
  (module
    (memory 1 2)
    (data (i32.const 0x1_0000) "a")
  )
  "out of bounds memory access"
)
