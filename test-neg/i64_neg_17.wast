(assert_invalid (module (func (result i64) (i64.clz (i32.const 0)))) "type mismatch")
