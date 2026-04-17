(module $M2
  (memory (export "mem") 1)

  (func (export "load") (param i32) (result i64)
    (i64.load (local.get 0))
  )
  (func (export "store") (param i32 i64)
    (i64.store (local.get 0) (local.get 1))
  )
)
