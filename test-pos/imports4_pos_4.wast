(module $Mgim1
  ;; imported memory limits should match, because external memory size is 2 now
  (import "test" "memory-2-4" (memory 1))
  (memory $m (export "memory") (import "grown-memory" "memory") 2) 
  (memory 0)
  (memory 0)
  (func (export "grow") (result i32) (memory.grow $m (i32.const 1)))
)
