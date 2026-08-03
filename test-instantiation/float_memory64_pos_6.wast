(module
  (memory i64 (data "\01\00\00\00\00\00\fc\7f"))

  (func (export "f64.load") (result f64) (f64.load (i64.const 0)))
  (func (export "i64.load") (result i64) (i64.load (i64.const 0)))
  (func (export "f64.store") (f64.store (i64.const 0) (f64.const nan:0xc000000000001)))
  (func (export "i64.store") (i64.store (i64.const 0) (i64.const 0x7ffc000000000001)))
  (func (export "reset") (i64.store (i64.const 0) (i64.const 0)))
)
