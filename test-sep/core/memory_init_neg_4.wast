(assert_invalid
  (module
    (memory 1)
    (data "\37")
    (func (export "test")
      (memory.init 1 (i32.const 1234) (i32.const 1) (i32.const 1))))
  "unknown data segment 1")
