(assert_invalid (module (func (result v128) (v128.not (i32.const 0)))) "type mismatch")
