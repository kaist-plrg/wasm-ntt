(assert_invalid (module (func (result f64) (f64.trunc (i64.const 0)))) "type mismatch")
