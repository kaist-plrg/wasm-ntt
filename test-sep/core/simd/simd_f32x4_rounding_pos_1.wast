(module
  (func (export "f32x4.ceil") (param v128) (result v128) (f32x4.ceil (local.get 0)))
  (func (export "f32x4.floor") (param v128) (result v128) (f32x4.floor (local.get 0)))
  (func (export "f32x4.trunc") (param v128) (result v128) (f32x4.trunc (local.get 0)))
  (func (export "f32x4.nearest") (param v128) (result v128) (f32x4.nearest (local.get 0)))
)
