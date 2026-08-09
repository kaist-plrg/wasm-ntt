(assert_invalid
  (module
    (func $i8x16.min_u-arg-empty (result v128)
      (i8x16.min_u)
    )
  )
  "type mismatch"
)
