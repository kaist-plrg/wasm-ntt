(assert_invalid (module (func (result f64) (f64.promote_f32 (i32.const 0)))) "type mismatch")
