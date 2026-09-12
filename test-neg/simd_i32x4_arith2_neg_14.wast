(assert_invalid
  (module
    (func $i32x4.abs-arg-empty (result v128)
      (i32x4.abs)
    )
  )
  "type mismatch"
)
