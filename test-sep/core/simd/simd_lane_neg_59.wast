(assert_invalid (module (func (result v128) (f64x2.replace_lane 0 (v128.const f64x2 0 0) (i64.const 1)))) "type mismatch")
