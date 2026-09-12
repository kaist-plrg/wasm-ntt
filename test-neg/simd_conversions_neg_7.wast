(assert_invalid (module (func (result v128) (i16x8.narrow_i32x4_s (f32.const 0.0) (f64.const 0.0)))) "type mismatch")
