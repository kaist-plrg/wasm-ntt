(assert_invalid (module (func (result f32) (f32.trunc (i64.const 0)))) "type mismatch")
