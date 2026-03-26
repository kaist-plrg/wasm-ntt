(assert_invalid
  (module
    (table $t 0 externref)
    (func $type-size-empty-vs-i32 (result i32)
      (table.grow $t (ref.null extern))
    )
  )
  "type mismatch"
)
