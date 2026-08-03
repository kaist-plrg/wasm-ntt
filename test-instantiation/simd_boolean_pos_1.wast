(module
  (func (export "i8x16.any_true") (param $0 v128) (result i32) (v128.any_true (local.get $0)))
  (func (export "i8x16.all_true") (param $0 v128) (result i32) (i8x16.all_true (local.get $0)))
  (func (export "i8x16.bitmask") (param $0 v128) (result i32) (i8x16.bitmask (local.get $0)))

  (func (export "i16x8.any_true") (param $0 v128) (result i32) (v128.any_true (local.get $0)))
  (func (export "i16x8.all_true") (param $0 v128) (result i32) (i16x8.all_true (local.get $0)))
  (func (export "i16x8.bitmask") (param $0 v128) (result i32) (i16x8.bitmask (local.get $0)))

  (func (export "i32x4.any_true") (param $0 v128) (result i32) (v128.any_true (local.get $0)))
  (func (export "i32x4.all_true") (param $0 v128) (result i32) (i32x4.all_true (local.get $0)))
  (func (export "i32x4.bitmask") (param $0 v128) (result i32) (i32x4.bitmask (local.get $0)))

  (func (export "i64x2.all_true") (param $0 v128) (result i32) (i64x2.all_true (local.get $0)))
  (func (export "i64x2.bitmask") (param $0 v128) (result i32) (i64x2.bitmask (local.get $0)))
)
