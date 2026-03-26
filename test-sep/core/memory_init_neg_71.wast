(assert_invalid
  (module
    (memory i64 1)
    (data "\37")
    (func (export "test")
      (memory.init 1 (i64.const 1234) (i32.const 1) (i32.const 1))))
  "unknown data segment 1")
