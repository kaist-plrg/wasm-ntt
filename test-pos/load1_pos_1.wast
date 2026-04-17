(module $M
  (memory (export "mem") 2)

  (func (export "read") (param i32) (result i32)
    (i32.load8_u (local.get 0))
  )
)
