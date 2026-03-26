(assert_invalid (module (func (result v128) (i16x8.replace_lane 0 (v128.const i16x8 0 0 0 0 0 0 0 0) (f64.const 1.0)))) "type mismatch")
