(module $Mgm
  (memory 0)
  (memory 0)
  (memory $m (export "memory") 1) ;; initial size is 1
  (func (export "grow") (result i32) (memory.grow $m (i32.const 1)))
)
