(module
  (func (export "test-consistent-nondeterminism") (param v128 v128 v128) (result v128)
    (f32x4.eq
      (f32x4.relaxed_madd (v128.const f32x4 0x1.fffffep+127 0x1.fffffep+127 0x1.fffffep+127 0x1.fffffep+127 )
                          (v128.const f32x4 2.0 2.0 2.0 2.0)
                          (v128.const f32x4 -0x1.fffffep+127 -0x1.fffffep+127 -0x1.fffffep+127 -0x1.fffffep+127))
      (f32x4.relaxed_madd (local.get 0)
                          (local.get 1)
                          (local.get 2))
    )
  )
)
