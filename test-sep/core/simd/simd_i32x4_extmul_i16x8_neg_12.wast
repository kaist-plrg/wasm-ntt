(assert_invalid
  (module
    (func $i32x4.extmul_high_i16x8_u-arg-empty (result v128)
      (i32x4.extmul_high_i16x8_u)
    )
  )
  "type mismatch"
)
