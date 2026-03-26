(assert_invalid (module (func (result i32) (i32.reinterpret_f32 (i64.const 0)))) "type mismatch")
