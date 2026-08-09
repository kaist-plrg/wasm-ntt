(assert_invalid (module (func (result v128) (i8x16.replace_lane 0 (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) (f32.const 1.0)))) "type mismatch")
