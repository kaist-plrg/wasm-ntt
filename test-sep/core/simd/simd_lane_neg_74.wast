(assert_invalid
  (module
    (func $i16x8.replace_lane-3rd-arg-empty (result v128)
      (i16x8.replace_lane 0 (v128.const i16x8 0 0 0 0 0 0 0 0))
    )
  )
  "type mismatch"
)
