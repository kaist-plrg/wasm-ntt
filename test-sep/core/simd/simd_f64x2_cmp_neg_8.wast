(assert_invalid
  (module
    (func $f64x2.eq-arg-empty (result v128)
      (f64x2.eq)
    )
  )
  "type mismatch"
)
