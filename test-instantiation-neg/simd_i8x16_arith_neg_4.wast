(assert_invalid
  (module
    (func $i8x16.neg-arg-empty (result v128)
      (i8x16.neg)
    )
  )
  "type mismatch"
)
