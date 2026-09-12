(assert_invalid (module (memory 0) (func (result v128) (v128.load8x8_s (f32.const 0)))) "type mismatch")
