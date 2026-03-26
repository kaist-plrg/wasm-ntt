(assert_invalid
  (module
    (func $f32x4.gt-arg-empty (result v128)
      (f32x4.gt)
    )
  )
  "type mismatch"
)
