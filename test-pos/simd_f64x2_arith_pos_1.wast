(module
  (func (export "f64x2.add") (param v128 v128) (result v128) (f64x2.add (local.get 0) (local.get 1)))
  (func (export "f64x2.sub") (param v128 v128) (result v128) (f64x2.sub (local.get 0) (local.get 1)))
  (func (export "f64x2.mul") (param v128 v128) (result v128) (f64x2.mul (local.get 0) (local.get 1)))
  (func (export "f64x2.div") (param v128 v128) (result v128) (f64x2.div (local.get 0) (local.get 1)))
  (func (export "f64x2.neg") (param v128) (result v128) (f64x2.neg (local.get 0)))
  (func (export "f64x2.sqrt") (param v128) (result v128) (f64x2.sqrt (local.get 0)))
)
