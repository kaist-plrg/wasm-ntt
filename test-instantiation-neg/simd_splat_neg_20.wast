(assert_invalid
  (module
    (func $f32x4.splat-arg-empty (result v128)
      (f32x4.splat)
    )
  )
  "type mismatch"
)
