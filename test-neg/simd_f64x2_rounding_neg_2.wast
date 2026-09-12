(assert_invalid (module (func (result v128) (f64x2.floor (i32.const 0)))) "type mismatch")
