(assert_invalid (module (func (result i32) (i16x8.extract_lane_s 8 (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)))) "invalid lane index")
