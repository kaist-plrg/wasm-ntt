(assert_invalid (module (func (result f64) (f64x2.extract_lane 0 (f64.const 0.0)))) "type mismatch")
