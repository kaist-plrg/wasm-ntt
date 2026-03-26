(module
  (func (export "f32x4.min") (param v128 v128) (result v128) (f32x4.min (local.get 0) (local.get 1)))
  (func (export "f32x4.max") (param v128 v128) (result v128) (f32x4.max (local.get 0) (local.get 1)))
  (func (export "f32x4.abs") (param v128) (result v128) (f32x4.abs (local.get 0)))
  ;; f32x4.min const vs const
  (func (export "f32x4.min_with_const_0") (result v128) (f32x4.min (v128.const f32x4 0 1 2 -3) (v128.const f32x4 0 2 1 3)))
  (func (export "f32x4.min_with_const_1") (result v128) (f32x4.min (v128.const f32x4 0 1 2 3) (v128.const f32x4 0 1 2 3)))
  (func (export "f32x4.min_with_const_2") (result v128) (f32x4.min (v128.const f32x4 0x00 0x01 0x02 0x80000000) (v128.const f32x4 0x00 0x02 0x01 2147483648)))
  (func (export "f32x4.min_with_const_3") (result v128) (f32x4.min (v128.const f32x4 0x00 0x01 0x02 0x80000000) (v128.const f32x4 0x00 0x01 0x02 0x80000000)))
  ;; f32x4.min param vs const
  (func (export "f32x4.min_with_const_5")(param v128) (result v128) (f32x4.min (local.get 0) (v128.const f32x4 0 1 2 -3)))
  (func (export "f32x4.min_with_const_6")(param v128) (result v128) (f32x4.min (v128.const f32x4 0 1 2 3) (local.get 0)))
  (func (export "f32x4.min_with_const_7")(param v128) (result v128) (f32x4.min (v128.const f32x4 0x00 0x01 0x02 0x80000000) (local.get 0)))
  (func (export "f32x4.min_with_const_8")(param v128) (result v128) (f32x4.min (local.get 0) (v128.const f32x4 0x00 0x01 0x02 0x80000000)))
  ;; f32x4.max const vs const
  (func (export "f32x4.max_with_const_10") (result v128) (f32x4.max (v128.const f32x4 0 1 2 -3) (v128.const f32x4 0 2 1 3)))
  (func (export "f32x4.max_with_const_11") (result v128) (f32x4.max (v128.const f32x4 0 1 2 3) (v128.const f32x4 0 1 2 3)))
  (func (export "f32x4.max_with_const_12") (result v128) (f32x4.max (v128.const f32x4 0x00 0x01 0x02 0x80000000) (v128.const f32x4 0x00 0x02 0x01 2147483648)))
  (func (export "f32x4.max_with_const_13") (result v128) (f32x4.max (v128.const f32x4 0x00 0x01 0x02 0x80000000) (v128.const f32x4 0x00 0x01 0x02 0x80000000)))
  ;; f32x4.max param vs const
  (func (export "f32x4.max_with_const_15")(param v128) (result v128) (f32x4.max (local.get 0) (v128.const f32x4 0 1 2 -3)))
  (func (export "f32x4.max_with_const_16")(param v128) (result v128) (f32x4.max (v128.const f32x4 0 1 2 3) (local.get 0)))
  (func (export "f32x4.max_with_const_17")(param v128) (result v128) (f32x4.max (v128.const f32x4 0x00 0x01 0x02 0x80000000) (local.get 0)))
  (func (export "f32x4.max_with_const_18")(param v128) (result v128) (f32x4.max (local.get 0) (v128.const f32x4 0x00 0x01 0x02 0x80000000)))

  (func (export "f32x4.abs_with_const") (result v128) (f32x4.abs (v128.const f32x4 -0 -1 -2 -3)))
)
