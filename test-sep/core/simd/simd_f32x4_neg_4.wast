(assert_invalid
  (module
    (func $f32x4.abs-arg-empty (result v128)
      (f32x4.abs)
    )
  )
  "type mismatch"
)
