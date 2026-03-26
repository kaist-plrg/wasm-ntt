(assert_invalid
  (module
    (func $f64x2.ge-arg-empty (result v128)
      (f64x2.ge)
    )
  )
  "type mismatch"
)
