(assert_invalid
  (module
    (func (export "testfn")
      (memory.fill (i32.const 10) (i32.const 20) (i32.const 30))))
  "unknown memory 0")
