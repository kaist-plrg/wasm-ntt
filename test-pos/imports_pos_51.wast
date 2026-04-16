(module
  (import "spectest" "memory" (memory 1 2))
  (import "test" "memory-2-inf" (memory 2))
  (import "test" "memory64-2-inf" (memory i64 2))
  (data (memory 0) (i32.const 10) "\10")

  (func (export "load") (param i32) (result i32) (i32.load (local.get 0)))
)
