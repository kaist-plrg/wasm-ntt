(assert_invalid (module (func (result i32) (i8x16.extract_lane_s 0 (i32.const 0)))) "type mismatch")
