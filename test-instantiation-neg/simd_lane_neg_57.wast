(assert_invalid (module (func (result v128) (f32x4.replace_lane 0 (v128.const f32x4 0 0 0 0) (i32.const 1)))) "type mismatch")
