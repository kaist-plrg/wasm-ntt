(assert_invalid (module (func (result f64) (f64.eq (i64.const 0) (f32.const 0)))) "type mismatch")
