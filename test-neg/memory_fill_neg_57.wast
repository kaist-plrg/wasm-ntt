(assert_invalid
  (module
    (memory 1 1)
    (func (export "testfn")
      (memory.fill (f64.const 10) (i64.const 20) (i32.const 30))))
  "type mismatch")
