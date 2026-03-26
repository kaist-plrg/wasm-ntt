(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-index-empty-vs-i32
      (table.fill $t (ref.null extern) (i32.const 1))
    )
  )
  "type mismatch"
)
