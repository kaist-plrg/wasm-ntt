(module
  (memory i64 1)
    (data "\37")
  (func (export "test")
    (data.drop 0)
    (memory.init 0 (i64.const 1234) (i32.const 1) (i32.const 1))))
