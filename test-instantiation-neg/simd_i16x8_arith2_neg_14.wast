(assert_invalid
  (module
    (func $i16x8.max_u-arg-empty (result v128)
      (i16x8.max_u)
    )
  )
  "type mismatch"
)
