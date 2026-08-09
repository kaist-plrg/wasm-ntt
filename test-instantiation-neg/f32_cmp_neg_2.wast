(assert_invalid (module (func (result f32) (f32.ge (i64.const 0) (f64.const 0)))) "type mismatch")
