(module
  (func (export "i64x2.add") (param v128 v128) (result v128) (i64x2.add (local.get 0) (local.get 1)))
  (func (export "i64x2.sub") (param v128 v128) (result v128) (i64x2.sub (local.get 0) (local.get 1)))
  (func (export "i64x2.mul") (param v128 v128) (result v128) (i64x2.mul (local.get 0) (local.get 1)))
  (func (export "i64x2.neg") (param v128) (result v128) (i64x2.neg (local.get 0)))
)
