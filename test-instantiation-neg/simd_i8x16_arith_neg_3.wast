(assert_invalid (module (func (result v128) (i8x16.sub (i32.const 0) (f32.const 0.0)))) "type mismatch")
