(assert_invalid
  (module
    (func $i64x2.neg-arg-empty (result v128)
      (i64x2.neg)
    )
  )
  "type mismatch"
)
