(assert_invalid (module (func (result v128) (i16x8.sub_sat_s (i32.const 0) (f32.const 0.0)))) "type mismatch")
