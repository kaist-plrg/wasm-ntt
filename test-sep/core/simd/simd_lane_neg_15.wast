(assert_invalid (module (func (result v128) (i16x8.replace_lane 16 (v128.const i16x8 0 0 0 0 0 0 0 0) (i32.const 1)))) "invalid lane index")
