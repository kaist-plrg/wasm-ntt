(assert_invalid
  (module
    (func $i32x4.trunc_sat_f64x2_s_zero-arg-empty (result v128)
      (i32x4.trunc_sat_f64x2_s_zero)
    )
  )
  "type mismatch"
)
