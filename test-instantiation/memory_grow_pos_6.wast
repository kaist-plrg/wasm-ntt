(module
  (memory (export "mem1") 2 5)
  (memory (export "mem2") 0)
)

(register "M")

(module
  (memory $mem1 (import "M" "mem1") 1 6)
  (memory $mem2 (import "M" "mem2") 0)
  (memory $mem3 3)
  (memory $mem4 4 5)

  (func (export "size1") (result i32) (memory.size $mem1))
  (func (export "size2") (result i32) (memory.size $mem2))
  (func (export "size3") (result i32) (memory.size $mem3))
  (func (export "size4") (result i32) (memory.size $mem4))

  (func (export "grow1") (param i32) (result i32)
    (memory.grow $mem1 (local.get 0))
  )
  (func (export "grow2") (param i32) (result i32)
    (memory.grow $mem2 (local.get 0))
  )
  (func (export "grow3") (param i32) (result i32)
    (memory.grow $mem3 (local.get 0))
  )
  (func (export "grow4") (param i32) (result i32)
    (memory.grow $mem4 (local.get 0))
  )
)
