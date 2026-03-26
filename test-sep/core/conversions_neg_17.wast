(assert_invalid (module (func (result f32) (f32.convert_i64_u (i32.const 0)))) "type mismatch")
