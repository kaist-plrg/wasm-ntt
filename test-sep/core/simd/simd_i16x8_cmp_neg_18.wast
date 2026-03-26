(assert_invalid
  (module
    (func $i16x8.lt_u-arg-empty (result v128)
      (i16x8.lt_u)
    )
  )
  "type mismatch"
)
