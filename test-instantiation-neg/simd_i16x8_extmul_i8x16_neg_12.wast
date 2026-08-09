(assert_invalid
  (module
    (func $i16x8.extmul_high_i8x16_u-arg-empty (result v128)
      (i16x8.extmul_high_i8x16_u)
    )
  )
  "type mismatch"
)
