(assert_invalid (module (func (result v128) (i8x16.replace_lane 0 (i32.const 0) (i32.const 1)))) "type mismatch")
