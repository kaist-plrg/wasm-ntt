(module
  (memory i64 1)
    (data "\37")
  (func (export "test")
    (memory.init 0 (i64.const 0x10001) (i32.const 4) (i32.const 0))))
