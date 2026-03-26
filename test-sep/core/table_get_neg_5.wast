(assert_invalid
  (module
    (table $t1 1 funcref)
    (table $t2 1 externref)
    (func $type-result-externref-vs-funcref-multi (result funcref)
      (table.get $t2 (i32.const 0))
    )
  )
  "type mismatch"
)
