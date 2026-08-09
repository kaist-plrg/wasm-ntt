(assert_invalid
  (module
    (func $i8x16.narrow_i16x8_u-arg-empty (result v128)
      (i8x16.narrow_i16x8_u)
    )
  )
  "type mismatch"
)
