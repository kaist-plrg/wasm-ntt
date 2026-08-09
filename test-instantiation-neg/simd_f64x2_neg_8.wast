(assert_invalid
  (module
    (func $f64x2.max-arg-empty (result v128)
      (f64x2.max)
    )
  )
  "type mismatch"
)
