(assert_invalid
  (module
    (func $i16x8.eq-arg-empty (result v128)
      (i16x8.eq)
    )
  )
  "type mismatch"
)
