(assert_trap
  (module
    (memory 2 2)
    (memory 1 2)
    (memory 2 2)
    (data (memory 1) (i32.const 0x1_0000) "a")
  )
  "out of bounds memory access"
)
