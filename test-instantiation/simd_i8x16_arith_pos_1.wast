(module
  (func (export "i8x16.add") (param v128 v128) (result v128) (i8x16.add (local.get 0) (local.get 1)))
  (func (export "i8x16.sub") (param v128 v128) (result v128) (i8x16.sub (local.get 0) (local.get 1)))
  (func (export "i8x16.neg") (param v128) (result v128) (i8x16.neg (local.get 0)))
)
