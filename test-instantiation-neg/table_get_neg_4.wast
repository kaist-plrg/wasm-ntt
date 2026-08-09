(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-result-externref-vs-funcref (result funcref)
      (table.get $t (i32.const 1))
    )
  )
  "type mismatch"
)
