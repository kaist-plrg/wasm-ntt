(assert_invalid (module (func (result v128) (i64x2.replace_lane 0 (v128.const i64x2 0 0) (f64.const 1.0)))) "type mismatch")
