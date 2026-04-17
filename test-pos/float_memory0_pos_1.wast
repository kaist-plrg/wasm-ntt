(module
  (memory 0 0)
  (memory 0 0)
  (memory 0 0)
  (memory $m (data "\00\00\a0\7f"))
  (memory 0 0)
  (memory 0 0)

  (func (export "f32.load") (result f32) (f32.load $m (i32.const 0)))
  (func (export "i32.load") (result i32) (i32.load $m (i32.const 0)))
  (func (export "f32.store") (f32.store $m (i32.const 0) (f32.const nan:0x200000)))
  (func (export "i32.store") (i32.store $m (i32.const 0) (i32.const 0x7fa00000)))
  (func (export "reset") (i32.store $m (i32.const 0) (i32.const 0)))
)
