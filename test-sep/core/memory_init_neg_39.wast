(assert_invalid
  (module
    (memory 1)
    (data "\37")
    (func (export "test")
      (memory.init 0 (i64.const 1) (i32.const 1) (f64.const 1))))
  "type mismatch")
