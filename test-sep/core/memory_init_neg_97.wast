(assert_invalid
  (module
    (memory i64 1)
    (data "\37")
    (func (export "test")
      (memory.init 0 (f32.const 1) (i64.const 1) (f32.const 1))))
  "type mismatch")
