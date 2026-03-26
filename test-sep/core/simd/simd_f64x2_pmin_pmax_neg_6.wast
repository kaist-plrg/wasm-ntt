(assert_invalid
  (module
    (func $f64x2.pmax-arg-empty (result v128)
      (f64x2.pmax)
    )
  )
  "type mismatch"
)
