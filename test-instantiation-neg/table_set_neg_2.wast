(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-index-empty-vs-i32
      (table.set $t (ref.null extern))
    )
  )
  "type mismatch"
)
