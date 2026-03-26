(assert_invalid
  (module
    (func $i64x2.extmul_low_i32x4_s-1st-arg-empty (result v128)
      (i64x2.extmul_low_i32x4_s (v128.const i64x2 0 0))
    )
  )
  "type mismatch"
)
