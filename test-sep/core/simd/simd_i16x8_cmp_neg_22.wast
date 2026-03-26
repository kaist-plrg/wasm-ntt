(assert_invalid
  (module
    (func $i16x8.le_u-arg-empty (result v128)
      (i16x8.le_u)
    )
  )
  "type mismatch"
)
