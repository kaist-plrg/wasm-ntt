(assert_invalid
  (module
    (func $f64x2.ne-arg-empty (result v128)
      (f64x2.ne)
    )
  )
  "type mismatch"
)
