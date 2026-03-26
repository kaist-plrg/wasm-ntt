(module
  (memory i64 1)
  (func (export "store") (param i64 i64)
    (i64.store align=4 (local.get 0) (local.get 1))
  )
  (func (export "load") (param i64) (result i32)
    (i32.load (local.get 0))
  )
)
