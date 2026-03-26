(assert_invalid (module (memory i64 1) (func (result f64) (f64.load (f32.const 0)))) "type mismatch")
