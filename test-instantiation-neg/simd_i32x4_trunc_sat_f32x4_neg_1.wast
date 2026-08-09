(assert_invalid (module (func (result v128) (i32x4.trunc_sat_f32x4_s (i32.const 0)))) "type mismatch")
