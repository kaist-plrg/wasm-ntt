(module $Mgm
  (memory (export "memory") 1) ;; initial size is 1
  (func (export "grow") (result i32) (memory.grow (i32.const 1)))
)
