(assert_invalid (module (memory 0) (func (result v128) (v128.load32_zero (f32.const 0)))) "type mismatch")
