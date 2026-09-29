(module
  (memory i64 1 1)
  (data (i64.const 0) "\aa\bb\cc\dd")

  (func (export "copy") (param i64 i64 i64)
    (memory.copy
      (local.get 0)
      (local.get 1)
      (local.get 2)))

  (func (export "load8_u") (param i64) (result i32)
    (i32.load8_u (local.get 0)))
)
