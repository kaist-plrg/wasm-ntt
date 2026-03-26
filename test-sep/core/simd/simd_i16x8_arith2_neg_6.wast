(assert_invalid (module (func (result v128) (i16x8.abs (f32.const 0.0)))) "type mismatch")
