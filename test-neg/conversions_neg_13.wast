(assert_invalid (module (func (result i64) (i64.reinterpret_f64 (i32.const 0)))) "type mismatch")
