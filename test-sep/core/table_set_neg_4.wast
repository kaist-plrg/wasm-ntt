(assert_invalid
  (module
    (table $t 10 externref)
    (func $type-size-f32-vs-i32
      (table.set $t (f32.const 1) (ref.null extern))
    )
  )
  "type mismatch"
)
