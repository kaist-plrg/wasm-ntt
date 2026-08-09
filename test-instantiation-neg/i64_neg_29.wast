(assert_invalid (module (func (result i64) (i64.ne (i32.const 0) (f32.const 0)))) "type mismatch")
