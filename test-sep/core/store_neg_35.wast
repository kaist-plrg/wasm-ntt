(assert_invalid (module (memory 1) (func (i32.store8 (f32.const 0) (i32.const 0)))) "type mismatch")
