(assert_invalid
  (module
    (func $i8x16.extract_lane_s-2nd-arg-empty (result i32)
      (i8x16.extract_lane_s 0)
    )
  )
  "type mismatch"
)
