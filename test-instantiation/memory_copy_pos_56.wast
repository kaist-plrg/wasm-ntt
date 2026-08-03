(module
  (memory i64 1 1)
  (func (export "test")
    (memory.copy (i64.const 0xFFFFFF00) (i64.const 0x4000) (i64.const 257))))
