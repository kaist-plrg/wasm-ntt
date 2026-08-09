(assert_invalid
  (module
    (func $i32x4.extend_low_i16x8_u-arg-empty (result v128)
      (i32x4.extend_low_i16x8_u)
    )
  )
  "type mismatch"
)
