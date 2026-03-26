(assert_invalid
  (module
    (func $f64x2.sqrt-arg-empty (result v128)
      (f64x2.sqrt)
    )
  )
  "type mismatch"
)
