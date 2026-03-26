(assert_invalid (module (memory 0) (func (result v128) (v128.load32x2_u (v128.const i32x4 0 0 0 0)))) "type mismatch")
