(assert_invalid
  (module
    (func $i8x16.max_u-arg-empty (result v128)
      (i8x16.max_u)
    )
  )
  "type mismatch"
)
