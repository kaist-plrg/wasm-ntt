(assert_invalid
  (module
    (table $t 0 funcref)
    (func $type-value-vs-funcref (param $r externref)
      (table.fill $t (i32.const 1) (local.get $r) (i32.const 1))
    )
  )
  "type mismatch"
)
