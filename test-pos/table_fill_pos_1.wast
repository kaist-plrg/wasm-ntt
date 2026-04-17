(module
  (table $t 10 externref)

  (func (export "fill") (param $i i32) (param $r externref) (param $n i32)
    (table.fill $t (local.get $i) (local.get $r) (local.get $n))
  )

  (func (export "fill-abbrev") (param $i i32) (param $r externref) (param $n i32)
    (table.fill (local.get $i) (local.get $r) (local.get $n))
  )

  (func (export "get") (param $i i32) (result externref)
    (table.get $t (local.get $i))
  )

  (table $t64 i64 10 externref)

  (func (export "fill-t64") (param $i i64) (param $r externref) (param $n i64)
    (table.fill $t64 (local.get $i) (local.get $r) (local.get $n))
  )

  (func (export "get-t64") (param $i i64) (result externref)
    (table.get $t64 (local.get $i))
  )
)
