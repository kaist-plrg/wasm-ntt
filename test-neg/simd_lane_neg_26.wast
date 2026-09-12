(assert_invalid (module (func (result v128) (i64x2.replace_lane 255 (v128.const i64x2 0 0) (i64.const 1)))) "invalid lane index")
