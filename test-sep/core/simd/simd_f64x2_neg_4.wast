(assert_invalid
  (module
    (func $f64x2.abs-arg-empty (result v128)
      (f64x2.abs)
    )
  )
  "type mismatch"
)
