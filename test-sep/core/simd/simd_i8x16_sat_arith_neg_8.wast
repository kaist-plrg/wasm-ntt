(assert_invalid
  (module
    (func $i8x16.add_sat_u-arg-empty (result v128)
      (i8x16.add_sat_u)
    )
  )
  "type mismatch"
)
