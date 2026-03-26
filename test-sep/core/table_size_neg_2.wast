(assert_invalid
  (module
    (table $t 1 externref)
    (func $type-result-i32-vs-f32 (result f32)
      (table.size $t)
    )
  )
  "type mismatch"
)
