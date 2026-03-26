(assert_invalid (module (func (result v128) (f32x4.ceil (i32.const 0)))) "type mismatch")
