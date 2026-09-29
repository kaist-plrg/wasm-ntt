(module
  (memory i64 1)
  (data "\aa\bb\cc\dd")

  (func (export "init") (param i64 i32 i32)
    (memory.init 0
      (local.get 0)
      (local.get 1)
      (local.get 2)))

  (func (export "load8_u") (param i64) (result i32)
    (i32.load8_u (local.get 0)))
)
