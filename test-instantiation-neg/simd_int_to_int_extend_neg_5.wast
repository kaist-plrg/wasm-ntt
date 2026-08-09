(assert_invalid (module (func (result v128) (i32x4.extend_high_i16x8_s (i32.const 0)))) "type mismatch")
