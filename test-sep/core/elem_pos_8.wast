(module
  (global (import "spectest" "global_i32") i32)
  (table 1000 funcref)
  (func $f)
  (elem (global.get 0) $f)
)
