(module $Mgm
  (memory (export "memory") 1) ;; initial size is 1
  (func (export "grow") (result i32) (memory.grow (i32.const 1)))
)

(register "grown-memory" $Mgm)

(assert_return (invoke $Mgm "grow") (i32.const 1))

(module $Mgim1
  ;; imported memory limits should match, because external memory size is 2 now
  (memory (export "memory") (import "grown-memory" "memory") 2)
  (func (export "grow") (result i32) (memory.grow (i32.const 1)))
)

(register "grown-imported-memory" $Mgim1)

(assert_return (invoke $Mgim1 "grow") (i32.const 2))

(module $Mgim2
  ;; imported memory limits should match, because external memory size is 3 now
  (import "grown-imported-memory" "memory" (memory 3))
  (func (export "size") (result i32) (memory.size))
)
