(assert_invalid
  (module
    (func $i32x4.trunc_sat_f32x4_s-arg-empty (result v128)
      (i32x4.trunc_sat_f32x4_s)
    )
  )
  "type mismatch"
)
