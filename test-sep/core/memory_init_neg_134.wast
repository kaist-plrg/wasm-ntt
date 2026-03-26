(assert_invalid
  (module
    (memory i64 1)
    (data "\37")
    (func (export "test")
      (memory.init 0 (f64.const 1) (f64.const 1) (f64.const 1))))
  "type mismatch")
