(module
  (memory 0)
  (memory 0)
  (memory 0)
  (memory 0)
  (memory $m 0)
  
  (func (export "size") (result i32) (memory.size $m))
  (func (export "grow") (param $sz i32) (drop (memory.grow $m (local.get $sz))))
)
