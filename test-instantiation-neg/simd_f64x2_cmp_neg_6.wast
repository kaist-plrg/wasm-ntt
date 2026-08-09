(assert_invalid (module (func (result v128) (f64x2.ge (i32.const 0) (f32.const 0.0)))) "type mismatch")
