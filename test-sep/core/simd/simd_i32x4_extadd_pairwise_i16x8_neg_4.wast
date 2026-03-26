(assert_invalid
  (module
    (func $i32x4.extadd_pairwise_i16x8_u-arg-empty (result v128)
      (i32x4.extadd_pairwise_i16x8_u)
    )
  )
  "type mismatch"
)
