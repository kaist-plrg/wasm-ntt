(assert_invalid
  (module
    (func $i8x16.sub_sat_s-arg-empty (result v128)
      (i8x16.sub_sat_s)
    )
  )
  "type mismatch"
)
