(assert_invalid
  (module
    (func $f32x4.replace_lane-2nd-arg-empty (result v128)
      (f32x4.replace_lane 0 (f32.const 1.0))
    )
  )
  "type mismatch"
)
