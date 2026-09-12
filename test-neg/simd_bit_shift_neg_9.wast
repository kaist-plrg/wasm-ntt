(assert_invalid (module (func (result v128) (i32x4.shr_u (i32.const 0) (i32.const 0)))) "type mismatch")
