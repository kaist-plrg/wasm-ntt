(module $G1 (global (export "g") i32 (i32.const 5)))

(register "G1" $G1)

(module $G2
  (global (import "G1" "g") i32)
  (global (export "g") i32 (global.get 0))
)
