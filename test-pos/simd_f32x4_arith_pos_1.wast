(module
  (func (export "f32x4.add") (param v128 v128) (result v128) (f32x4.add (local.get 0) (local.get 1)))
  (func (export "f32x4.sub") (param v128 v128) (result v128) (f32x4.sub (local.get 0) (local.get 1)))
  (func (export "f32x4.mul") (param v128 v128) (result v128) (f32x4.mul (local.get 0) (local.get 1)))
  (func (export "f32x4.div") (param v128 v128) (result v128) (f32x4.div (local.get 0) (local.get 1)))
  (func (export "f32x4.neg") (param v128) (result v128) (f32x4.neg (local.get 0)))
  (func (export "f32x4.sqrt") (param v128) (result v128) (f32x4.sqrt (local.get 0)))
)
