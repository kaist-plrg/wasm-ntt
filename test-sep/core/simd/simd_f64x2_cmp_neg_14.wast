(assert_invalid
  (module
    (func $f64x2.le-arg-empty (result v128)
      (f64x2.le)
    )
  )
  "type mismatch"
)
