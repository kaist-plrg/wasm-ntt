(assert_invalid (module (func (result v128) (v128.or (i32.const 0) (i32.const 0)))) "type mismatch")
