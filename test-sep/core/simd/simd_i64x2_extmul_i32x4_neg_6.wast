(assert_invalid
  (module
    (func $i64x2.extmul_low_i32x4_s-arg-empty (result v128)
      (i64x2.extmul_low_i32x4_s)
    )
  )
  "type mismatch"
)
