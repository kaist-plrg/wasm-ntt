(assert_invalid
  (module
    (func $i8x16.eq-arg-empty (result v128)
      (i8x16.eq)
    )
  )
  "type mismatch"
)
