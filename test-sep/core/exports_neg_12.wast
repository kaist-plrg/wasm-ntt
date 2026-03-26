(assert_invalid
  (module (import "spectest" "global_i32" (global i32)) (export "a" (global 1)))
  "unknown global"
)
