(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-index-f32-vs-i32 (result externref)
      (table.get $t (f32.const 1))
    )
  )
  "type mismatch"
)
