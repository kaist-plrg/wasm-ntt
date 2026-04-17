(module
  (memory i64 1)
    (data "\37")
  (func (export "test")
    (memory.init 0 (i64.const 0x10000) (i32.const 1) (i32.const 0))))
