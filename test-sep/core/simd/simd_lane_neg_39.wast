(assert_invalid (module (func (result v128) (f64x2.replace_lane 2 (v128.const f64x2 0 0) (f64.const 1.0)))) "invalid lane index")
