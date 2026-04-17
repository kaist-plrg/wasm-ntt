(module $module4
  (func (result i32)
    i32.const 42
  )
  (global (export "f") funcref (ref.func 0))
)
