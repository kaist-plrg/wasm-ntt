(assert_invalid
  (module
    (func $i8x16.narrow_i16x8_u-1st-arg-empty (result v128)
      (i8x16.narrow_i16x8_u (v128.const i16x8 0 0 0 0 0 0 0 0))
    )
  )
  "type mismatch"
)
