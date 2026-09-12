(assert_invalid (module (func (result f64) (f64.max (i64.const 0) (f32.const 0)))) "type mismatch")
