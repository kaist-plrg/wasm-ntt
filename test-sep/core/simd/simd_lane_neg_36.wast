(assert_invalid (module (func (result i64) (i64x2.extract_lane 2 (v128.const i64x2 0 0)))) "invalid lane index")
