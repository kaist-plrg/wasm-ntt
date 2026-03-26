(assert_invalid
  (module
    (func $i8x16.replace_lane-3rd-arg-empty (result v128)
      (i8x16.replace_lane 0 (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0))
    )
  )
  "type mismatch"
)
