(module

  (func (export "f32x4_sqrt_arith") (result v128)
    (f32x4.sqrt (v128.const f32x4 nan:0x200000 -nan:0x200000 16.0 25.0)))
  (func (export "f32x4_sqrt_canon") (result v128)
    (f32x4.sqrt (v128.const f32x4 -1.0 nan 4.0 9.0)))
  (func (export "f32x4_sqrt_mixed") (result v128)
    (f32x4.sqrt (v128.const f32x4 -inf nan:0x200000 36.0 49.0)))
)
