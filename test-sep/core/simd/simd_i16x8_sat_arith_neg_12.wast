(assert_invalid
  (module
    (func $i16x8.sub_sat_u-arg-empty (result v128)
      (i16x8.sub_sat_u)
    )
  )
  "type mismatch"
)
