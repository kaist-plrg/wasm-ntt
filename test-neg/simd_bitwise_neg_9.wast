(assert_invalid (module (func (result v128) (v128.xor (v128.const i32x4 0 0 0 0) (i32.const 0)))) "type mismatch")
