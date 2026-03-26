(module
  (func (export "f64x2.eq") (param v128 v128) (result v128) (f64x2.eq (local.get 0) (local.get 1)))
  (func (export "f64x2.ne") (param v128 v128) (result v128) (f64x2.ne (local.get 0) (local.get 1)))
  (func (export "f64x2.lt") (param v128 v128) (result v128) (f64x2.lt (local.get 0) (local.get 1)))
  (func (export "f64x2.le") (param v128 v128) (result v128) (f64x2.le (local.get 0) (local.get 1)))
  (func (export "f64x2.gt") (param v128 v128) (result v128) (f64x2.gt (local.get 0) (local.get 1)))
  (func (export "f64x2.ge") (param v128 v128) (result v128) (f64x2.ge (local.get 0) (local.get 1)))
)
