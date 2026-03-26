(assert_invalid (module (func (result v128) (i16x8.shr_s (i32.const 0) (i32.const 0)))) "type mismatch")
