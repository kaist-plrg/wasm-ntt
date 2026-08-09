(assert_invalid
  (module
    (func $f64x2.floor-arg-empty (result v128)
      (f64x2.floor)
    )
  )
  "type mismatch"
)
