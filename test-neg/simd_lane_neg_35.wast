(assert_invalid (module (func (result v128) (f32x4.replace_lane 4 (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) (f32.const 1)))) "invalid lane index")
