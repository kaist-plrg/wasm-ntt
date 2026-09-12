(assert_invalid
  (module
    (memory i64 1)
    (data "\37")
    (func (export "test")
      (memory.init 0 (i32.const 1) (f64.const 1) (i32.const 1))))
  "type mismatch")
