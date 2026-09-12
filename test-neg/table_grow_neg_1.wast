(assert_invalid
  (module
    (table $t 0 externref)
    (func $type-init-size-empty-vs-i32-externref (result i32)
      (table.grow $t)
    )
  )
  "type mismatch"
)
