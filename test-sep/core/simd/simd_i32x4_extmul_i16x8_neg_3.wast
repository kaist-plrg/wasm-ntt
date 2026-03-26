(assert_invalid (module (func (result v128) (i32x4.extmul_low_i16x8_u (i32.const 0) (f32.const 0.0)))) "type mismatch")
