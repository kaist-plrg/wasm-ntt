(module
  (global $g (import "spectest" "global_i32") i32)
  (memory 1)
  (data (global.get $g) "a")
)
