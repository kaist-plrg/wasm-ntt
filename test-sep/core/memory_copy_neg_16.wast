(assert_invalid
  (module
    (memory 1 1)
    (func (export "testfn")
      (memory.copy (i32.const 10) (f64.const 20) (f64.const 30))))
  "type mismatch")
