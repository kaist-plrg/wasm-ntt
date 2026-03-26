(assert_invalid (module (func (result v128) (f32x4.floor (i32.const 0)))) "type mismatch")
