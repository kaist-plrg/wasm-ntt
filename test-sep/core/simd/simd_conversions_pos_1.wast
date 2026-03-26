(module
  ;; Integer to floating point
  (func (export "f32x4.convert_i32x4_s") (param v128) (result v128)
    (f32x4.convert_i32x4_s (local.get 0)))
  (func (export "f32x4.convert_i32x4_u") (param v128) (result v128)
    (f32x4.convert_i32x4_u (local.get 0)))

  (func (export "f64x2.convert_low_i32x4_s") (param v128) (result v128)
    (f64x2.convert_low_i32x4_s (local.get 0)))
  (func (export "f64x2.convert_low_i32x4_u") (param v128) (result v128)
    (f64x2.convert_low_i32x4_u (local.get 0)))

  ;; Integer to integer narrowing
  (func (export "i8x16.narrow_i16x8_s") (param v128 v128) (result v128)
    (i8x16.narrow_i16x8_s (local.get 0) (local.get 1)))
  (func (export "i8x16.narrow_i16x8_u") (param v128 v128) (result v128)
    (i8x16.narrow_i16x8_u (local.get 0) (local.get 1)))
  (func (export "i16x8.narrow_i32x4_s") (param v128 v128) (result v128)
    (i16x8.narrow_i32x4_s (local.get 0) (local.get 1)))
  (func (export "i16x8.narrow_i32x4_u") (param v128 v128) (result v128)
    (i16x8.narrow_i32x4_u (local.get 0)(local.get 1)))

  ;; Float to float promote/demote
  (func (export "f64x2.promote_low_f32x4") (param v128) (result v128)
    (f64x2.promote_low_f32x4 (local.get 0)))
  (func (export "f32x4.demote_f64x2_zero") (param v128) (result v128)
    (f32x4.demote_f64x2_zero (local.get 0)))
)
