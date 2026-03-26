(module
  (memory (data "\00\00\00\a0\7f"))

  (func (export "f32.load") (result f32) (f32.load (i32.const 1)))
  (func (export "i32.load") (result i32) (i32.load (i32.const 1)))
  (func (export "f32.store") (f32.store (i32.const 1) (f32.const nan:0x200000)))
  (func (export "i32.store") (i32.store (i32.const 1) (i32.const 0x7fa00000)))
  (func (export "reset") (i32.store (i32.const 1) (i32.const 0)))
)
