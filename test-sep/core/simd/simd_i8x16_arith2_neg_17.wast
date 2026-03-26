(assert_invalid
  (module
    (func $i8x16.avgr_u-arg-empty (result v128)
      (i8x16.avgr_u)
    )
  )
  "type mismatch"
)
