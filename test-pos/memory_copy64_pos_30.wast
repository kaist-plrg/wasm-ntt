(module
  (memory i64 1 1)
  (func (export "test")
    (memory.copy (i64.const 0x9000) (i64.const 0x20000) (i64.const 0))))
