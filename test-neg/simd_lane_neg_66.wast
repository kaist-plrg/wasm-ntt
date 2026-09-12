(assert_invalid
  (module
    (func $i16x8.extract_lane_u-2nd-arg-empty (result i32)
      (i16x8.extract_lane_u 0)
    )
  )
  "type mismatch"
)
