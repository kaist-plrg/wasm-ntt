(assert_invalid (module (func (result f64) (f64.sqrt (i64.const 0)))) "type mismatch")
