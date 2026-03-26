(assert_invalid
  (module
    (func $i64x2.extend_high_i32x4_s-arg-empty (result v128)
      (i64x2.extend_high_i32x4_s)
    )
  )
  "type mismatch"
)
