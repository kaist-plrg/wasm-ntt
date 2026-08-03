(assert_trap
  (module
    (memory 3)
    (memory 3)
    (memory 2)
    (data (memory 2) (i32.const 0x2_0000) "a")
  )
  "out of bounds memory access"
)
