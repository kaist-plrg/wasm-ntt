(assert_invalid
  (module
    (table $t 0 externref)
    (func $type-index-f32-vs-i32
      (table.fill $t (f32.const 1) (ref.null extern) (i32.const 1))
    )
  )
  "type mismatch"
)
