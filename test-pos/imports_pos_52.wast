(module
  (memory (import "spectest" "memory") 1 2)
  (memory (import "test" "memory-2-inf") 2)
  (memory (import "test" "memory64-2-inf") i64 2)
  (data (memory 0) (i32.const 10) "\10")

  (func (export "load") (param i32) (result i32) (i32.load (local.get 0)))
)
