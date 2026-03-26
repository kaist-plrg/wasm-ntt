(assert_invalid
  (module
    (func $i16x8.avgr_u-arg-empty (result v128)
      (i16x8.avgr_u)
    )
  )
  "type mismatch"
)
