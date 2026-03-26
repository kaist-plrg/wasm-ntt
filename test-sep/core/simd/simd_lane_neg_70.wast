(assert_invalid
  (module
    (func $f64x2.extract_lane-2nd-arg-empty (result f64)
      (f64x2.extract_lane 0)
    )
  )
  "type mismatch"
)
