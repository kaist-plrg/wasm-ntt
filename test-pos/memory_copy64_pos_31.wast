(module
  (memory i64 1 1)
  (func (export "test")
    (memory.copy (i64.const 0x10000) (i64.const 0x10000) (i64.const 0))))
