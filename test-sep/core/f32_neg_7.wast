(assert_invalid (module (func (result f32) (f32.ceil (i64.const 0)))) "type mismatch")
