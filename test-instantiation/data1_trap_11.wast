(assert_trap
  (module
    (memory 0)
    (memory 0)
    (memory 1)
    (data (memory 2) (i32.const -1) "a")
  )
  "out of bounds memory access"
)
