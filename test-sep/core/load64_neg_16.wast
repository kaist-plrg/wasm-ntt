(assert_invalid (module (memory i64 1) (func (result i32) (i32.load8_s (f32.const 0)))) "type mismatch")
