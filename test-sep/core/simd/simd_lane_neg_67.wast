(assert_invalid
  (module
    (func $i32x4.extract_lane-2nd-arg-empty (result i32)
      (i32x4.extract_lane 0)
    )
  )
  "type mismatch"
)
