(assert_trap
  (module
    (import "spectest" "memory" (memory 1))
    (data (i32.const 0x1_0000) "a")
  )
  "out of bounds memory access"
)
