(assert_invalid
  (module
    (func $f32x4.max-arg-empty (result v128)
      (f32x4.max)
    )
  )
  "type mismatch"
)
