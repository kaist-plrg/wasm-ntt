(assert_invalid
  (module (memory (import "M" "m") 0 0x1_0000_0000))
  "memory size"
)
