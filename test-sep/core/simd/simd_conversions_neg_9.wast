(assert_invalid
  (module
    (func $f32x4.convert_i32x4_s-arg-empty (result v128)
      (f32x4.convert_i32x4_s)
    )
  )
  "type mismatch"
)
