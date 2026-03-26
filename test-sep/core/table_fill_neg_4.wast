(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-length-empty-vs-i32
      (table.fill $t (i32.const 1) (ref.null extern))
    )
  )
  "type mismatch"
)
