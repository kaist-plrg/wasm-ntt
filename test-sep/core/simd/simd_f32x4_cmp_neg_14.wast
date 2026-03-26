(assert_invalid
  (module
    (func $f32x4.le-arg-empty (result v128)
      (f32x4.le)
    )
  )
  "type mismatch"
)
