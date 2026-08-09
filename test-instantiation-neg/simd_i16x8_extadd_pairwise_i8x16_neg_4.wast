(assert_invalid
  (module
    (func $i16x8.extadd_pairwise_i8x16_u-arg-empty (result v128)
      (i16x8.extadd_pairwise_i8x16_u)
    )
  )
  "type mismatch"
)
