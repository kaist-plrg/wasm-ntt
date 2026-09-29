(module
  (table $t64 i64 0 externref)

  (func (export "get-t64") (param $i i64) (result externref) (table.get $t64 (local.get $i)))
  (func (export "set-t64") (param $i i64) (param $r externref) (table.set $t64 (local.get $i) (local.get $r)))
  (func (export "grow-t64") (param $sz i64) (param $init externref) (result i64)
    (table.grow $t64 (local.get $init) (local.get $sz))
  )
  (func (export "size-t64") (result i64) (table.size $t64))
)
