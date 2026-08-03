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

(assert_return (invoke "grow" (i32.const 0)) (i32.const 1))

(assert_return (invoke "grow" (i32.const 1)) (i32.const 1))

(assert_return (invoke "grow" (i32.const 0)) (i32.const 2))

(assert_return (invoke "grow" (i32.const 1)) (i32.const -1))

(assert_return (invoke "grow" (i32.const 0)) (i32.const 2))

(module $Mgm
  (memory 0)
  (memory 0)
  (memory $m (export "memory") 1) ;; initial size is 1
  (func (export "grow") (result i32) (memory.grow $m (i32.const 1)))
)

(register "grown-memory" $Mgm)

(assert_return (invoke $Mgm "grow") (i32.const 1))

(module $Mgim1
  ;; imported memory limits should match, because external memory size is 2 now
  (import "test" "memory-2-4" (memory 1))
  (memory $m (export "memory") (import "grown-memory" "memory") 2) 
  (memory 0)
  (memory 0)
  (func (export "grow") (result i32) (memory.grow $m (i32.const 1)))
)
