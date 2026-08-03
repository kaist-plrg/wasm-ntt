(assert_trap
  (module
    (memory 2)
    (data (i32.const 0x2_0000) "a")
  )
  "out of bounds memory access"
)
