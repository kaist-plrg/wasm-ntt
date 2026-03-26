(module
  (memory $mem0 (data "\ff\11\44\ee"))
  (memory $mem1 (data "\ee\22\55\ff"))
  (memory $mem2 (data "\dd\33\66\00"))
  (memory $mem3 (data "\aa\bb\cc\dd"))

  (func (export "copy") (param i32 i32 i32)
    (memory.copy $mem3 $mem3
      (local.get 0)
      (local.get 1)
      (local.get 2)))

  (func (export "load8_u") (param i32) (result i32)
    (i32.load8_u $mem3 (local.get 0)))
)
