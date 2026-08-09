(module $observe_M_func_provider
  (func (export "f") (param i32) (result i32) (local.get 0))
  (func (export "g") (param i32) (result i32) (local.get 0))
)
(register "M" $observe_M_func_provider)
