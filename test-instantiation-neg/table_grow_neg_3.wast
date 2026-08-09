(assert_invalid
  (module
    (table $t 0 externref)
    (func $type-init-empty-vs-externref (result i32)
      (table.grow $t (i32.const 1))
    )
  )
  "type mismatch"
)
