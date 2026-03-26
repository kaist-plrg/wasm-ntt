(assert_invalid
  (module
    (func $i16x8.min_u-arg-empty (result v128)
      (i16x8.min_u)
    )
  )
  "type mismatch"
)
