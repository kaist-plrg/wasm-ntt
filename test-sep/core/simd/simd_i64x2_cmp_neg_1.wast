(assert_invalid (module (func (result v128) (i64x2.eq (i32.const 0) (f32.const 0)))) "type mismatch")
