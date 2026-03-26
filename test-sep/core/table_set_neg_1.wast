(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-index-value-empty-vs-i32-externref
      (table.set $t)
    )
  )
  "type mismatch"
)
