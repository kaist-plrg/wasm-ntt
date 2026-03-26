(assert_invalid (module (func (result i64) (i64.trunc_f64_s (i32.const 0)))) "type mismatch")
