(assert_invalid
  (module
    (func $f32x4.replace_lane-3rd-arg-empty (result v128)
      (f32x4.replace_lane 0 (v128.const f32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
