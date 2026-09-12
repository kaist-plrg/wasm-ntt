(assert_invalid
  (module
    (table $t 1 externref)
    (func $type-result-i32-vs-f32 (result f32)
      (table.grow $t (ref.null extern) (i32.const 0))
    )
  )
  "type mismatch"
)
