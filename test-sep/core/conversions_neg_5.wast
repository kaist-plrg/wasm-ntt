(assert_invalid (module (func (result i32) (i32.trunc_f64_u (i64.const 0)))) "type mismatch")
