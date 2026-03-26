(assert_invalid
  (module
    (func $f64x2.lt-arg-empty (result v128)
      (f64x2.lt)
    )
  )
  "type mismatch"
)
