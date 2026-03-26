(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-value-empty-vs-externref
      (table.set $t (i32.const 1))
    )
  )
  "type mismatch"
)
