(assert_trap
  (module
    (import "spectest" "memory" (memory 1))
    (import "spectest" "memory" (memory 1))
    (import "spectest" "memory" (memory 1))
    (data (memory 2) (i32.const -1) "a")
  )
  "out of bounds memory access"
)
