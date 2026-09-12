(assert_invalid (module (memory 0) (func (result v128) (v128.load16x4_s (f64.const 0)))) "type mismatch")
