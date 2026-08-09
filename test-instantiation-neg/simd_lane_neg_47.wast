(assert_invalid (module (func (result v128) (i16x8.replace_lane 0 (i64.const 0) (i32.const 1)))) "type mismatch")
