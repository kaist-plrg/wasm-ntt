(assert_invalid
  (module
    (func (export "testfn")
      (memory.copy (i64.const 10) (i64.const 20) (i64.const 30))))
  "unknown memory 0")
