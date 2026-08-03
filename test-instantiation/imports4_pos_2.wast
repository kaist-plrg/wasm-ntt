(module
  (memory (export "memory-2-inf") 2)
  (memory (export "memory-2-4") 2 4)
)

(register "test")

(module
  (import "test" "memory-2-4" (memory 1))
  (memory $m (import "spectest" "memory") 0 3)  ;; actual has max size 2
  (func (export "grow") (param i32) (result i32) (memory.grow $m (local.get 0)))
)
