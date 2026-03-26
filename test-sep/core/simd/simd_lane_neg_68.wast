(assert_invalid
  (module
    (func $i64x2.extract_lane-2nd-arg-empty (result i64)
      (i64x2.extract_lane 0)
    )
  )
  "type mismatch"
)
