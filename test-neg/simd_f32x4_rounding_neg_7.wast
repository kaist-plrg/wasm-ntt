(assert_invalid
  (module
    (func $f32x4.trunc-arg-empty (result v128)
      (f32x4.trunc)
    )
  )
  "type mismatch"
)
