(assert_invalid
  (module
    (func $i16x8.sub_sat_s-arg-empty (result v128)
      (i16x8.sub_sat_s)
    )
  )
  "type mismatch"
)
