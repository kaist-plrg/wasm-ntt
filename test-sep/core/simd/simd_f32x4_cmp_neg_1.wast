(assert_invalid (module (func (result v128) (f32x4.eq (i64.const 0) (f64.const 0)))) "type mismatch")
