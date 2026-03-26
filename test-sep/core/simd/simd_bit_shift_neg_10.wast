(assert_invalid (module (func (result v128) (i64x2.shl   (i32.const 0) (i32.const 0)))) "type mismatch")
