(assert_invalid (module (func (result i32) (i32x4.extract_lane 4 (v128.const i32x4 0 0 0 0)))) "invalid lane index")
