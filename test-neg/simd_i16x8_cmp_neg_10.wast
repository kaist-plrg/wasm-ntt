(assert_invalid (module (func (result v128) (i16x8.ne (i32.const 0) (f32.const 0)))) "type mismatch")
