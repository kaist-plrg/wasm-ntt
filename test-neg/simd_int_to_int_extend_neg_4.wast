(assert_invalid (module (func (result v128) (i16x8.extend_low_i8x16_u (i32.const 0)))) "type mismatch")
