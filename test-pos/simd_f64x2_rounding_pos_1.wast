(module
  (func (export "f64x2.ceil") (param v128) (result v128) (f64x2.ceil (local.get 0)))
  (func (export "f64x2.floor") (param v128) (result v128) (f64x2.floor (local.get 0)))
  (func (export "f64x2.trunc") (param v128) (result v128) (f64x2.trunc (local.get 0)))
  (func (export "f64x2.nearest") (param v128) (result v128) (f64x2.nearest (local.get 0)))
)
