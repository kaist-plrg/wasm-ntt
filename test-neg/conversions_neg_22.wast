(assert_invalid (module (func (result f64) (f64.convert_i64_s (i32.const 0)))) "type mismatch")
