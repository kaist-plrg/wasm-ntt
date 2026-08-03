(module
  (memory (data "\aa\bb\cc\dd"))

  (func (export "copy") (param i32 i32 i32)
    (memory.copy
      (local.get 0)
      (local.get 1)
      (local.get 2)))

  (func (export "load8_u") (param i32) (result i32)
    (i32.load8_u (local.get 0)))
)
