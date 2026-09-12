(assert_invalid (module (func (result i64) (i64x2.extract_lane 0 (i64.const 0)))) "type mismatch")
