(assert_invalid (module (memory 1) (func (f32.store (i32.const 0) (i32.const 0)))) "type mismatch")
