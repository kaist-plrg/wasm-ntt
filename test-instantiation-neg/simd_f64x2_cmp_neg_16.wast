(assert_invalid
  (module
    (func $f64x2.gt-arg-empty (result v128)
      (f64x2.gt)
    )
  )
  "type mismatch"
)
