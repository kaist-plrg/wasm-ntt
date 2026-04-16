(module
  (func (export "i16x8.add") (param v128 v128) (result v128) (i16x8.add (local.get 0) (local.get 1)))
  (func (export "i16x8.sub") (param v128 v128) (result v128) (i16x8.sub (local.get 0) (local.get 1)))
  (func (export "i16x8.mul") (param v128 v128) (result v128) (i16x8.mul (local.get 0) (local.get 1)))
  (func (export "i16x8.neg") (param v128) (result v128) (i16x8.neg (local.get 0)))
)
