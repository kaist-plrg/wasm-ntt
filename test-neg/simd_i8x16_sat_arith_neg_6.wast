(assert_invalid
  (module
    (func $i8x16.add_sat_s-arg-empty (result v128)
      (i8x16.add_sat_s)
    )
  )
  "type mismatch"
)
