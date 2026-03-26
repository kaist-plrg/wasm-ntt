(assert_invalid (module (func (result i64) (i64.or (i32.const 0) (f32.const 0)))) "type mismatch")
