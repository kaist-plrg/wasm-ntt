(assert_invalid
  (module
    (func (export "testfn")
      (memory.fill (i64.const 10) (i32.const 20) (i64.const 30))))
  "unknown memory 0")
