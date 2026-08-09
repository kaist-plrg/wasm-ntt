(assert_invalid (module (memory 0) (func (result v128) (v128.load8_splat (v128.const i32x4 0 0 0 0)))) "type mismatch")
