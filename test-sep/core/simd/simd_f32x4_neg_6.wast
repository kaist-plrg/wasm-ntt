(assert_invalid
  (module
    (func $f32x4.min-arg-empty (result v128)
      (f32x4.min)
    )
  )
  "type mismatch"
)
