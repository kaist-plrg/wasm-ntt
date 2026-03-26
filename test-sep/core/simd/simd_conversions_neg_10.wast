(assert_invalid
  (module
    (func $f32x4.convert_i32x4_u-arg-empty (result v128)
      (f32x4.convert_i32x4_u)
    )
  )
  "type mismatch"
)
