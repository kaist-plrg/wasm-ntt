(assert_trap
  (module
    (memory 1)
    (data (i32.const -1) "a")
  )
  "out of bounds memory access"
)
