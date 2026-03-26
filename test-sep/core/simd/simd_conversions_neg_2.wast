(assert_invalid (module (func (result v128) (f32x4.convert_i32x4_s (i64.const 0)))) "type mismatch")
