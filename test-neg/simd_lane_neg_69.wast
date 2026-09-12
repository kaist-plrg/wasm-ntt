(assert_invalid
  (module
    (func $f32x4.extract_lane-2nd-arg-empty (result f32)
      (f32x4.extract_lane 0)
    )
  )
  "type mismatch"
)
