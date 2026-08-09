(assert_invalid (module (memory 1) (func (i64.store8 (i32.const 0) (f64.const 0)))) "type mismatch")
