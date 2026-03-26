(module $Mgim2
  ;; imported memory limits should match, because external memory size is 3 now
  (import "grown-imported-memory" "memory" (memory 3))
  (func (export "size") (result i32) (memory.size))
)
