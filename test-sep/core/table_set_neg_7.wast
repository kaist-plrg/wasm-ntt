(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-result-empty-vs-num (result i32)
      (table.set $t (i32.const 0) (ref.null extern))
    )
  )
  "type mismatch"
)
