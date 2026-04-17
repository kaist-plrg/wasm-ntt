(module $G2
  (global (import "G1" "g") i32)
  (global (export "g") i32 (global.get 0))
)
