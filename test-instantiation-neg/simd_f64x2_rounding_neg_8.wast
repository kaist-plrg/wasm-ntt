(assert_invalid
  (module
    (func $f64x2.nearest-arg-empty (result v128)
      (f64x2.nearest)
    )
  )
  "type mismatch"
)
