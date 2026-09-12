(assert_invalid
  (module
    (table $t 1 externref)
    (func $type-result-i32-vs-empty
      (table.size $t)
    )
  )
  "type mismatch"
)
