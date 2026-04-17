(module $Mgim2
  ;; imported memory limits should match, because external memory size is 3 now
  (import "test" "memory-2-4" (memory 1))
  (memory $m (import "grown-imported-memory" "memory") 3)
  (memory 0)
  (memory 0)
  (func (export "size") (result i32) (memory.size $m))
)
