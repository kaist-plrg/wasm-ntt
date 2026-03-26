(assert_invalid (module (func (result f32) (f32x4.extract_lane 0 (f32.const 0.0)))) "type mismatch")
