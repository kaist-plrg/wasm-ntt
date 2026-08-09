(assert_invalid
  (module
    (func $f64x2.mul-arg-empty (result v128)
      (f64x2.mul)
    )
  )
  "type mismatch"
)
