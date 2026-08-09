(assert_invalid
  (module
    (func $i16x8.neg-arg-empty (result v128)
      (i16x8.neg)
    )
  )
  "type mismatch"
)
