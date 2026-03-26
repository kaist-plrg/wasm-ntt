(module
  (global (import "spectest" "global_i32") i32)
  (import "spectest" "memory" (memory 0))
  (data (global.get 0) "a")
)
