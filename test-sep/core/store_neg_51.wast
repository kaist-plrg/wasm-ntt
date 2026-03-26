(assert_invalid (module (memory 1) (func (f64.store (i32.const 0) (i64.const 0)))) "type mismatch")
