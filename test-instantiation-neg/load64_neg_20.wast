(assert_invalid (module (memory i64 1) (func (result i64) (i64.load (f32.const 0)))) "type mismatch")
