(assert_invalid (module (func (result v128) (i8x16.replace_lane 255 (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) (i32.const 1)))) "invalid lane index")
