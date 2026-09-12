(assert_invalid (module (func (result v128) (i16x8.lt_u (i32.const 0) (f32.const 0)))) "type mismatch")
