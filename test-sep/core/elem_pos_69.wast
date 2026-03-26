(module $m
  (table $t (export "table") 2 externref)
  (func (export "get") (param $i i32) (result externref)
        (table.get $t (local.get $i)))
  (func (export "set") (param $i i32) (param $x externref)
        (table.set $t (local.get $i) (local.get $x))))
