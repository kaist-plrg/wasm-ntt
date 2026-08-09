(assert_invalid (module (func (result v128) (v128.andnot (i32.const 0) (i32.const 0)))) "type mismatch")
