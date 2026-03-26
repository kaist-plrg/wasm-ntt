(assert_invalid
  (module
    (memory i64 1 1)
    (func (export "testfn")
      (memory.fill (i32.const 10) (f64.const 20) (f64.const 30))))
  "type mismatch")
