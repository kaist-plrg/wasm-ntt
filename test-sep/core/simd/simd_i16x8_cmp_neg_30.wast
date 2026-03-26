(assert_invalid
  (module
    (func $i16x8.ge_u-arg-empty (result v128)
      (i16x8.ge_u)
    )
  )
  "type mismatch"
)
