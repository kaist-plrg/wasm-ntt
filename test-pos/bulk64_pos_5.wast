(module
  (memory i64 1)
  (data "")
  (data (i64.const 0) "")

  (func (export "drop_passive") (data.drop 0))
  (func (export "init_passive")
    (memory.init 0 (i64.const 0) (i32.const 0) (i32.const 0)))

  (func (export "drop_active") (data.drop 1))
  (func (export "init_active")
    (memory.init 1 (i64.const 0) (i32.const 0) (i32.const 0)))
)
