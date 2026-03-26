(assert_invalid (module (func (result f32) (f32.convert_i32_u (i64.const 0)))) "type mismatch")
