(assert_invalid
  (module
    (func $i8x16.replace_lane-2nd-arg-empty (result v128)
      (i8x16.replace_lane 0 (i32.const 1))
    )
  )
  "type mismatch"
)
