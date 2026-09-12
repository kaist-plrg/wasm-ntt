(assert_invalid
  (module
    (table $t 0 externref)
    (func $type-size-f32-vs-i32 (result i32)
      (table.grow $t (ref.null extern) (f32.const 1))
    )
  )
  "type mismatch"
)
