(assert_invalid
  (module
    (func $f64x2.trunc-arg-empty (result v128)
      (f64x2.trunc)
    )
  )
  "type mismatch"
)
