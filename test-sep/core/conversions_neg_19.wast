(assert_invalid (module (func (result f32) (f32.reinterpret_i32 (i64.const 0)))) "type mismatch")
