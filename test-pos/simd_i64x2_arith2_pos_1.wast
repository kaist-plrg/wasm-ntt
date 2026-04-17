(module
  (func (export "i64x2.abs") (param v128) (result v128) (i64x2.abs (local.get 0)))
  (func (export "i64x2.abs_with_const_0") (result v128) (i64x2.abs (v128.const i64x2 -9223372036854775808 9223372036854775807)))
)
