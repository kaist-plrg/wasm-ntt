(assert_invalid (module (func (result v128) (i8x16.abs (f32.const 0.0)))) "type mismatch")
