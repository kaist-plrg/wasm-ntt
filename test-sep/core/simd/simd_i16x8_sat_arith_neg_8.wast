(assert_invalid
  (module
    (func $i16x8.add_sat_u-arg-empty (result v128)
      (i16x8.add_sat_u)
    )
  )
  "type mismatch"
)
