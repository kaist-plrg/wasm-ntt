(assert_invalid
  (module
    (func $i64x2.replace_lane-2nd-arg-empty (result v128)
      (i64x2.replace_lane 0 (i64.const 1))
    )
  )
  "type mismatch"
)
