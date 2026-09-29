(module
  (memory (export "memory0") i64 1 1)
  (data (i64.const 2) "\03\01\04\01")
  (data (i64.const 12) "\07\05\02\03\06")
  (func (export "test")
    (memory.copy (i64.const 12) (i64.const 10) (i64.const 7)))
  (func (export "load8_u") (param i64) (result i32)
    (i32.load8_u (local.get 0))))
