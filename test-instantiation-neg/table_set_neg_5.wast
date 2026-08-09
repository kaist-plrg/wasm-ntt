(assert_invalid
  (module
    (table $t 10 funcref)
    (func $type-value-externref-vs-funcref (param $r externref)
      (table.set $t (i32.const 1) (local.get $r))
    )
  )
  "type mismatch"
)
