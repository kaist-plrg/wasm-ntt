(assert_invalid
  (module
    (func $i32x4.min_u-arg-empty (result v128)
      (i32x4.min_u)
    )
  )
  "type mismatch"
)
