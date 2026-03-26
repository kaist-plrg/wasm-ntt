(assert_invalid (module (memory 1) (func (f64.store (f32.const 0) (f64.const 0)))) "type mismatch")
