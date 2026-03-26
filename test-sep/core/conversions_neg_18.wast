(assert_invalid (module (func (result f32) (f32.demote_f64 (i32.const 0)))) "type mismatch")
