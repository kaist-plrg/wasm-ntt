(assert_invalid (module (func (result i32) (i32x4.extract_lane 0 (i32.const 0)))) "type mismatch")
