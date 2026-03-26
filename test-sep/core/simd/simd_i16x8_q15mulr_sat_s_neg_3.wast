(assert_invalid
  (module
    (func $i16x8.q15mulr_sat_s-arg-empty (result v128)
      (i16x8.q15mulr_sat_s)
    )
  )
  "type mismatch"
)
