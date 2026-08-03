(assert_trap
  (module
    (memory 3 3)
    (memory 2 3)
    (memory 3 3)
    (data (memory 1) (i32.const 0x2_0000) "a")
  )
  "out of bounds memory access"
)
