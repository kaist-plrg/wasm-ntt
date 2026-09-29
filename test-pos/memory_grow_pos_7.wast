(module $Mgim1
  ;; imported memory limits should match, because external memory size is 2 now
  (memory (export "memory") (import "grown-memory" "memory") 2)
  (func (export "grow") (result i32) (memory.grow (i32.const 1)))
)
