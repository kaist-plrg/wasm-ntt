(assert_invalid
  (module
    (memory i64 1 1)
    (func (export "testfn")
      (memory.copy (f32.const 10) (i64.const 20) (f32.const 30))))
  "type mismatch")
