(assert_invalid (module (func (result v128) (i8x16.ne (i32.const 0) (f32.const 0)))) "type mismatch")
