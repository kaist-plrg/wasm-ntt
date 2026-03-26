(assert_invalid (module (func (result i32) (i32.wrap_i64 (f32.const 0)))) "type mismatch")
