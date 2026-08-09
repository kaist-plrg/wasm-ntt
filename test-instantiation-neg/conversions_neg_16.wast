(assert_invalid (module (func (result f32) (f32.convert_i64_s (i32.const 0)))) "type mismatch")
