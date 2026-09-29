(module
  (table $t2 i64 2 externref)
  (table $t3 i64 3 funcref)
  (elem (table $t3) (i64.const 1) func $dummy)
  (func $dummy)

  (func (export "init") (param $r externref)
    (table.set $t2 (i64.const 1) (local.get $r))
    (table.set $t3 (i64.const 2) (table.get $t3 (i64.const 1)))
  )

  (func (export "get-externref") (param $i i64) (result externref)
    (table.get (local.get $i))
  )
  (func $f3 (export "get-funcref") (param $i i64) (result funcref)
    (table.get $t3 (local.get $i))
  )

  (func (export "is_null-funcref") (param $i i64) (result i32)
    (ref.is_null (call $f3 (local.get $i)))
  )
)
