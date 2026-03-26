(assert_invalid
  (module
    (func $f64x2.min-1st-arg-empty (result v128)
      (f64x2.min (v128.const f64x2 0 0))
    )
  )
  "type mismatch"
)
