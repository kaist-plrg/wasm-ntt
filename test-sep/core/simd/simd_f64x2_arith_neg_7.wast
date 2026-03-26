(assert_invalid
  (module
    (func $f64x2.neg-arg-empty (result v128)
      (f64x2.neg)
    )
  )
  "type mismatch"
)
