(assert_invalid
  (module
    (func (export "test")
      (memory.init 1 (i32.const 1234) (i32.const 1) (i32.const 1))))
  "unknown memory 0")
