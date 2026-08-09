(assert_invalid (module (func (result v128) (v128.and (i32.const 0) (i32.const 0)))) "type mismatch")
