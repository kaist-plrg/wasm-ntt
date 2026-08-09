(assert_invalid (module (func (result v128) (f64x2.sqrt (i64.const 0)))) "type mismatch")
