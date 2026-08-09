(assert_invalid (module (func (result f64) (f64x2.extract_lane 255 (v128.const f64x2 0 0)))) "invalid lane index")
