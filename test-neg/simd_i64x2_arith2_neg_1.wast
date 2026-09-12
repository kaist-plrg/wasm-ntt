(assert_invalid (module (func (result v128) (i64x2.abs (f32.const 0.0)))) "type mismatch")
