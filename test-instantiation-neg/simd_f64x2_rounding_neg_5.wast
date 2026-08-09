(assert_invalid
  (module
    (func $f64x2.ceil-arg-empty (result v128)
      (f64x2.ceil)
    )
  )
  "type mismatch"
)
