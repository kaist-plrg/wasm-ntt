(assert_invalid
  (module
    (func $i64x2.replace_lane-3rd-arg-empty (result v128)
      (i64x2.replace_lane 0 (v128.const i64x2 0 0))
    )
  )
  "type mismatch"
)
