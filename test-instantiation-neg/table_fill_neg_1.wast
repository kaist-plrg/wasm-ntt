(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-index-value-length-empty-vs-i32-i32
      (table.fill $t)
    )
  )
  "type mismatch"
)
