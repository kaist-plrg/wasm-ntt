(assert_invalid (module (func (result v128) (i16x8.neg (i32.const 0)))) "type mismatch")
