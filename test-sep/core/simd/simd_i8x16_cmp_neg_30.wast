(assert_invalid
  (module
    (func $i8x16.ge_u-arg-empty (result v128)
      (i8x16.ge_u)
    )
  )
  "type mismatch"
)
