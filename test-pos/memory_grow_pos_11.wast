(module
  (memory $mem1 1)
  (memory $mem2 2)

  (func (export "grow1") (param i32) (result i32)
    (memory.grow $mem1 (local.get 0))
  )
  (func (export "grow2") (param i32) (result i32)
    (memory.grow $mem2 (local.get 0))
  )

  (func (export "size1") (result i32) (memory.size $mem1))
  (func (export "size2") (result i32) (memory.size $mem2))
)
