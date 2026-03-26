(assert_invalid
  (module
    (func $i8x16.lt_u-arg-empty (result v128)
      (i8x16.lt_u)
    )
  )
  "type mismatch"
)
