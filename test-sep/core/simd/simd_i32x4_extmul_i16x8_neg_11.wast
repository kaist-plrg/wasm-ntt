(assert_invalid
  (module
    (func $i32x4.extmul_high_i16x8_u-1st-arg-empty (result v128)
      (i32x4.extmul_high_i16x8_u (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
