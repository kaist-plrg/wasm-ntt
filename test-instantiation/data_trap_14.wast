(assert_trap
  (module
    (import "spectest" "memory" (memory 1))
    (data (i32.const -100) "a")
  )
  "out of bounds memory access"
)
