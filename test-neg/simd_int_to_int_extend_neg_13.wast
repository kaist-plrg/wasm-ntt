(assert_invalid
  (module
    (func $i16x8.extend_high_i8x16_s-arg-empty (result v128)
      (i16x8.extend_high_i8x16_s)
    )
  )
  "type mismatch"
)
