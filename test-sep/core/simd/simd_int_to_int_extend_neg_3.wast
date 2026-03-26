(assert_invalid (module (func (result v128) (i16x8.extend_low_i8x16_s (i32.const 0)))) "type mismatch")
