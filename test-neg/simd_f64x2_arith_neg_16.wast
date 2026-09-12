(assert_invalid
  (module
    (func $f64x2.div-arg-empty (result v128)
      (f64x2.div)
    )
  )
  "type mismatch"
)
