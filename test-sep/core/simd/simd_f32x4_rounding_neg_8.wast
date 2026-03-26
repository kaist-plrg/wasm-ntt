(assert_invalid
  (module
    (func $f32x4.nearest-arg-empty (result v128)
      (f32x4.nearest)
    )
  )
  "type mismatch"
)
