(assert_invalid
  (module  (import "spectest" "memory" (memory 1 2)) (export "a" (memory 1)))
  "unknown memory"
)
