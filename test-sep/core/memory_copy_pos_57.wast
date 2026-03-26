(module
  (memory i64 1 1)
  (func (export "test")
    (memory.copy (i64.const 0x8000) (i64.const 0xFF00) (i64.const 257))))
