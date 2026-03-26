(module
  (import "test" "z" (memory 0))
  (memory $m (import "spectest" "memory") 1 2)
  (data (memory 1) (i32.const 10) "\10")

  (func (export "load") (param i32) (result i32) (i32.load $m (local.get 0)))
)
