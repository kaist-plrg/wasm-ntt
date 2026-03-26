(assert_invalid
  (module
    (table $t 1 externref)
    (func $type-result-empty-vs-num (result i32)
      (table.fill $t (i32.const 0) (ref.null extern) (i32.const 1))
    )
  )
  "type mismatch"
)
