(assert_invalid
  (module
    (func $i16x8.shr_u-arg-empty (result v128)
      (i16x8.shr_u)
    )
  )
  "type mismatch"
)
