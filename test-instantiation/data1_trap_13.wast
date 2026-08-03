(assert_trap
  (module
    (memory 2)
    (memory 2)
    (memory 2)
    (data (memory 2) (i32.const -100) "a")
  )
  "out of bounds memory access"
)
