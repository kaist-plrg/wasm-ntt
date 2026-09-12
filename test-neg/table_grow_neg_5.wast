(assert_invalid
  (module
    (table $t 0 funcref)
    (func $type-init-externref-vs-funcref (param $r externref) (result i32)
      (table.grow $t (local.get $r) (i32.const 1))
    )
  )
  "type mismatch"
)
