(assert_invalid
  (module
    (func $i64x2.extend_low_i32x4_u-arg-empty (result v128)
      (i64x2.extend_low_i32x4_u)
    )
  )
  "type mismatch"
)
