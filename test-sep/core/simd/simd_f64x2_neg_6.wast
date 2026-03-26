(assert_invalid
  (module
    (func $f64x2.min-arg-empty (result v128)
      (f64x2.min)
    )
  )
  "type mismatch"
)
