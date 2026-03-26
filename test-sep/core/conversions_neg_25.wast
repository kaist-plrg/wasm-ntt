(assert_invalid (module (func (result f64) (f64.reinterpret_i64 (i32.const 0)))) "type mismatch")
