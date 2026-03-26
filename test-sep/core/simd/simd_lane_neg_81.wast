(assert_invalid
  (module
    (func $f64x2.replace_lane-2nd-arg-empty (result v128)
      (f64x2.replace_lane 0 (f64.const 1.0))
    )
  )
  "type mismatch"
)
