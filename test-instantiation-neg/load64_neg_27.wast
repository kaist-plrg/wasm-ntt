(assert_invalid (module (memory i64 1) (func (result f32) (f32.load (f32.const 0)))) "type mismatch")
