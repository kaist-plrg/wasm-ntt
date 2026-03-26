(module
  (func (export "i8x16.shl") (param $0 v128) (param $1 i32) (result v128) (i8x16.shl (local.get $0) (local.get $1)))
  (func (export "i8x16.shr_s") (param $0 v128) (param $1 i32) (result v128) (i8x16.shr_s (local.get $0) (local.get $1)))
  (func (export "i8x16.shr_u") (param $0 v128) (param $1 i32) (result v128) (i8x16.shr_u (local.get $0) (local.get $1)))

  (func (export "i16x8.shl") (param $0 v128) (param $1 i32) (result v128) (i16x8.shl (local.get $0) (local.get $1)))
  (func (export "i16x8.shr_s") (param $0 v128) (param $1 i32) (result v128) (i16x8.shr_s (local.get $0) (local.get $1)))
  (func (export "i16x8.shr_u") (param $0 v128) (param $1 i32) (result v128) (i16x8.shr_u (local.get $0) (local.get $1)))

  (func (export "i32x4.shl") (param $0 v128) (param $1 i32) (result v128) (i32x4.shl (local.get $0) (local.get $1)))
  (func (export "i32x4.shr_s") (param $0 v128) (param $1 i32) (result v128) (i32x4.shr_s (local.get $0) (local.get $1)))
  (func (export "i32x4.shr_u") (param $0 v128) (param $1 i32) (result v128) (i32x4.shr_u (local.get $0) (local.get $1)))

  (func (export "i64x2.shl") (param $0 v128) (param $1 i32) (result v128) (i64x2.shl (local.get $0) (local.get $1)))
  (func (export "i64x2.shr_s") (param $0 v128) (param $1 i32) (result v128) (i64x2.shr_s (local.get $0) (local.get $1)))
  (func (export "i64x2.shr_u") (param $0 v128) (param $1 i32) (result v128) (i64x2.shr_u (local.get $0) (local.get $1)))

  ;; shifting by a constant amount
  ;; i8x16
  (func (export "i8x16.shl_1") (param $0 v128) (result v128) (i8x16.shl (local.get $0) (i32.const 1)))
  (func (export "i8x16.shr_u_8") (param $0 v128) (result v128) (i8x16.shr_u (local.get $0) (i32.const 8)))
  (func (export "i8x16.shr_s_9") (param $0 v128) (result v128) (i8x16.shr_s (local.get $0) (i32.const 9)))

  ;; i16x8
  (func (export "i16x8.shl_1") (param $0 v128) (result v128) (i16x8.shl (local.get $0) (i32.const 1)))
  (func (export "i16x8.shr_u_16") (param $0 v128) (result v128) (i16x8.shr_u (local.get $0) (i32.const 16)))
  (func (export "i16x8.shr_s_17") (param $0 v128) (result v128) (i16x8.shr_s (local.get $0) (i32.const 17)))

  ;; i32x4
  (func (export "i32x4.shl_1") (param $0 v128) (result v128) (i32x4.shl (local.get $0) (i32.const 1)))
  (func (export "i32x4.shr_u_32") (param $0 v128) (result v128) (i32x4.shr_u (local.get $0) (i32.const 32)))
  (func (export "i32x4.shr_s_33") (param $0 v128) (result v128) (i32x4.shr_s (local.get $0) (i32.const 33)))

  ;; i64x2
  (func (export "i64x2.shl_1") (param $0 v128) (result v128) (i64x2.shl (local.get $0) (i32.const 1)))
  (func (export "i64x2.shr_u_64") (param $0 v128) (result v128) (i64x2.shr_u (local.get $0) (i32.const 64)))
  (func (export "i64x2.shr_s_65") (param $0 v128) (result v128) (i64x2.shr_s (local.get $0) (i32.const 65)))
)
