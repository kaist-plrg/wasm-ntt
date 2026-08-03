(module
  (memory $mem0 0)
  (memory $mem1 0)
  (memory $mem2 1)
  (memory $mem3 0)
  (data $mem2 "\aa\bb\cc\dd")

  (func (export "init") (param i32 i32 i32)
    (memory.init $mem2 0
      (local.get 0)
      (local.get 1)
      (local.get 2)))

  (func (export "load8_u") (param i32) (result i32)
    (i32.load8_u $mem2 (local.get 0)))
)
