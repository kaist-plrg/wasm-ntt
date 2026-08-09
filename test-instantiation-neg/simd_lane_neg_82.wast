(assert_invalid
  (module
    (func $f64x2.replace_lane-3rd-arg-empty (result v128)
      (f64x2.replace_lane 0 (v128.const f64x2 0 0))
    )
  )
  "type mismatch"
)
