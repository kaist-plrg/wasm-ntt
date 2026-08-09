(assert_invalid
  (module
    (func $f64x2.sub-arg-empty (result v128)
      (f64x2.sub)
    )
  )
  "type mismatch"
)
