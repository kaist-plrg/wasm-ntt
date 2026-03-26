(assert_invalid (module (func (result f32) (f32.div (i64.const 0) (f64.const 0)))) "type mismatch")
