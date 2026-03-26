(module
  (func (export "f32x4.pmin") (param v128 v128) (result v128) (f32x4.pmin (local.get 0) (local.get 1)))
  (func (export "f32x4.pmax") (param v128 v128) (result v128) (f32x4.pmax (local.get 0) (local.get 1)))
)
