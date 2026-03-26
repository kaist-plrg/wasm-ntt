(assert_invalid (module (func (result i64) (i64.extend_i32_s (f32.const 0)))) "type mismatch")
