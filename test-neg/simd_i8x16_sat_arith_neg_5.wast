(assert_invalid
  (module
    (func $i8x16.add_sat_s-1st-arg-empty (result v128)
      (i8x16.add_sat_s (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0))
    )
  )
  "type mismatch"
)
