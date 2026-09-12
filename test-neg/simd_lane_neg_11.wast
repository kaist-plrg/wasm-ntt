(assert_invalid (module (func (result f32) (f32x4.extract_lane 4 (v128.const f32x4 0 0 0 0)))) "invalid lane index")
