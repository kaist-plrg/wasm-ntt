(assert_invalid
  (module
    (table $t 0 externref)
    (func $type-length-f32-vs-i32
      (table.fill $t (i32.const 1) (ref.null extern) (f32.const 1))
    )
  )
  "type mismatch"
)
