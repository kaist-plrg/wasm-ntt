(assert_invalid
  (module
    (func $f32x4.mul-arg-empty (result v128)
      (f32x4.mul)
    )
  )
  "type mismatch"
)
