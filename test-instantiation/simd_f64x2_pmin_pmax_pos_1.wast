(module
  (func (export "f64x2.pmin") (param v128 v128) (result v128) (f64x2.pmin (local.get 0) (local.get 1)))
  (func (export "f64x2.pmax") (param v128 v128) (result v128) (f64x2.pmax (local.get 0) (local.get 1)))
)
