(assert_invalid (module (func (result v128) (v128.bitselect (i32.const 0) (i32.const 0) (i32.const 0)))) "type mismatch")
