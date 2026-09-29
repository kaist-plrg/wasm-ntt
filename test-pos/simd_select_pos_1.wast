(module
  (func (export "select_v128_i32") (param v128 v128 i32) (result v128)
    (select (local.get 0) (local.get 1) (local.get 2))
  )
)
