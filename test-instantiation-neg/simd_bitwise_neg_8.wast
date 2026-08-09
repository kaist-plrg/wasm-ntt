(assert_invalid (module (func (result v128) (v128.xor (i32.const 0) (v128.const i32x4 0 0 0 0)))) "type mismatch")
