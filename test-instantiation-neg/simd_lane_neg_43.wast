(assert_invalid (module (func (result i32) (i8x16.extract_lane_u 0 (f64.const 0.0)))) "type mismatch")
