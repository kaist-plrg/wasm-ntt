(assert_invalid
  (module
    (memory 1 1)
    (func (export "testfn")
      (memory.fill (i64.const 10) (f32.const 20) (i64.const 30))))
  "type mismatch")
