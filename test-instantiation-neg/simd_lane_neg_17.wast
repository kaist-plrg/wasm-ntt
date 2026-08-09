(assert_invalid (module (func (result v128) (i32x4.replace_lane 4 (v128.const i32x4 0 0 0 0) (i32.const 1)))) "invalid lane index")
