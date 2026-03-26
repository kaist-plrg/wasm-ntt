(assert_invalid (module (func (result v128) (i32x4.ge_s (i32.const 0) (f32.const 0)))) "type mismatch")
