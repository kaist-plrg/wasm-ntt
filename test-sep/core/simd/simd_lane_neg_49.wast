(assert_invalid (module (func (result v128) (f32x4.replace_lane 0 (f32.const 0.0) (i32.const 1)))) "type mismatch")
