(assert_trap
  (module
    (import "spectest" "memory" (memory 1))
    (import "spectest" "memory" (memory 1))
    (import "spectest" "memory" (memory 1))
    (import "spectest" "memory" (memory 1))
    (data (memory 3) (i32.const -100) "a")
  )
  "out of bounds memory access"
)
