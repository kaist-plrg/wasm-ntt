(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-value-empty-vs
      (table.fill $t (i32.const 1) (i32.const 1))
    )
  )
  "type mismatch"
)
