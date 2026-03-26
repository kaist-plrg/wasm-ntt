(module
  (memory i64 (data "\01\00\d0\7f"))

  (func (export "f32.load") (result f32) (f32.load (i64.const 0)))
  (func (export "i32.load") (result i32) (i32.load (i64.const 0)))
  (func (export "f32.store") (f32.store (i64.const 0) (f32.const nan:0x500001)))
  (func (export "i32.store") (i32.store (i64.const 0) (i32.const 0x7fd00001)))
  (func (export "reset") (i32.store (i64.const 0) (i32.const 0)))
)
