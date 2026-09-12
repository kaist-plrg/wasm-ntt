(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-result-externref-vs-empty
      (table.get $t (i32.const 0))
    )
  )
  "type mismatch"
)
