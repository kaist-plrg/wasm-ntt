(assert_invalid (module (func (result v128) (f64x2.mul (i64.const 0) (f64.const 0.0)))) "type mismatch")
