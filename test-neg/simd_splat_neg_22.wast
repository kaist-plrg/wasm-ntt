(assert_invalid
  (module
    (func $f64x2.splat-arg-empty (result v128)
      (f64x2.splat)
    )
  )
  "type mismatch"
)
