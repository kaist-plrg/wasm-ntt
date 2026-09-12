(assert_invalid
  (module
    (func $i32x4.replace_lane-3rd-arg-empty (result v128)
      (i32x4.replace_lane 0 (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
