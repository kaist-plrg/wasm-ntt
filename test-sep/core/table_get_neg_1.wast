(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-index-empty-vs-i32 (result externref)
      (table.get $t)
    )
  )
  "type mismatch"
)
