(assert_invalid
  (module
    (table $t1 1 externref)
    (table $t2 1 funcref)
    (func $type-value-externref-vs-funcref-multi (param $r externref)
      (table.set $t2 (i32.const 0) (local.get $r))
    )
  )
  "type mismatch"
)
