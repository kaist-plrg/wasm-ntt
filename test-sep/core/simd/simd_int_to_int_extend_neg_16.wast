(assert_invalid
  (module
    (func $i16x8.extend_low_i8x16_u-arg-empty (result v128)
      (i16x8.extend_low_i8x16_u)
    )
  )
  "type mismatch"
)
