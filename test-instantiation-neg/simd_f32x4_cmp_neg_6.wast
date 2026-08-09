(assert_invalid (module (func (result v128) (f32x4.ne (i64.const 0) (f64.const 0)))) "type mismatch")
