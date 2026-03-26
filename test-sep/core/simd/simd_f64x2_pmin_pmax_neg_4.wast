(assert_invalid
  (module
    (func $f64x2.pmin-arg-empty (result v128)
      (f64x2.pmin)
    )
  )
  "type mismatch"
)
