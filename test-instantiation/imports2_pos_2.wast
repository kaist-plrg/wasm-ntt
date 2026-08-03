(module
  (memory (export "z") 0 0)
  (memory (export "memory-2-inf") 2)
  (memory (export "memory-2-4") 2 4)
)

(register "test")

(module
  (import "test" "z" (memory 0))
  (memory $m (import "spectest" "memory") 1 2)
  (data (memory 1) (i32.const 10) "\10")

  (func (export "load") (param i32) (result i32) (i32.load $m (local.get 0)))
)
