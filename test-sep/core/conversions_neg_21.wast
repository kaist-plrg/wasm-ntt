(assert_invalid (module (func (result f64) (f64.convert_i32_u (i64.const 0)))) "type mismatch")
