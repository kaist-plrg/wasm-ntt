(assert_invalid
  (module
    (func (export "test")
      (table.init 0 (i32.const 12) (i32.const 1) (i32.const 1))))
  "unknown table 0")
