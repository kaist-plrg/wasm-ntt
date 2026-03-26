(module
  (memory i64 1)
    (data "\37")
  (func (export "test")
    (memory.init 0 (i64.const 1234) (i32.const 2) (i32.const 3))))
