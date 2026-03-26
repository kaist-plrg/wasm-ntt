(assert_invalid
  (module
    (func $f64x2.add-arg-empty (result v128)
      (f64x2.add)
    )
  )
  "type mismatch"
)
