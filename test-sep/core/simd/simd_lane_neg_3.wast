(assert_invalid (module (func (result i32) (i8x16.extract_lane_u 16 (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)))) "invalid lane index")
