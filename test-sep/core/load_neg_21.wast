(assert_invalid (module (memory 1) (func (result i64) (i64.load8_s (f32.const 0)))) "type mismatch")
