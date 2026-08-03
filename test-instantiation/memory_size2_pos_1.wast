(module
  (memory 0 0)
  (memory 0 0)
  (memory $n 0 0)
  (memory $m 0 2)
  
  (func (export "size") (result i32) (memory.size $m))
  (func (export "grow") (param $sz i32) (drop (memory.grow $m (local.get $sz))))

  (func (export "sizen") (result i32) (memory.size $n))
  (func (export "grown") (param $sz i32) (drop (memory.grow $n (local.get $sz))))
)
