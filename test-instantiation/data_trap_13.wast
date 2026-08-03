(assert_trap
  (module
    (memory 2)
    (data (i32.const -100) "a")
  )
  "out of bounds memory access"
)
