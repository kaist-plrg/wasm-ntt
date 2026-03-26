(assert_invalid (module (func (result i64) (i64.eqz (i32.const 0)))) "type mismatch")
