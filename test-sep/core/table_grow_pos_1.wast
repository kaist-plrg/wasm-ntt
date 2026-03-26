(module
  (table $t 0 externref)

  (func (export "get") (param $i i32) (result externref) (table.get $t (local.get $i)))
  (func (export "set") (param $i i32) (param $r externref) (table.set $t (local.get $i) (local.get $r)))

  (func (export "grow") (param $sz i32) (param $init externref) (result i32)
    (table.grow $t (local.get $init) (local.get $sz))
  )
  (func (export "grow-abbrev") (param $sz i32) (param $init externref) (result i32)
    (table.grow (local.get $init) (local.get $sz))
  )
  (func (export "size") (result i32) (table.size $t))

  (table $t64 i64 0 externref)

  (func (export "get-t64") (param $i i64) (result externref) (table.get $t64 (local.get $i)))
  (func (export "set-t64") (param $i i64) (param $r externref) (table.set $t64 (local.get $i) (local.get $r)))
  (func (export "grow-t64") (param $sz i64) (param $init externref) (result i64)
    (table.grow $t64 (local.get $init) (local.get $sz))
  )
  (func (export "size-t64") (result i64) (table.size $t64))
)
