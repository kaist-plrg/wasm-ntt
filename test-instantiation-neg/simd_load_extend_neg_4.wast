(assert_invalid (module (memory 0) (func (result v128) (v128.load16x4_u (f64.const 0)))) "type mismatch")
