(assert_invalid (module (func (result v128) (f32x4.ge (i64.const 0) (f64.const 0)))) "type mismatch")
