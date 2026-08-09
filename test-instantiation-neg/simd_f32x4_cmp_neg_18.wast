(assert_invalid
  (module
    (func $f32x4.ge-arg-empty (result v128)
      (f32x4.ge)
    )
  )
  "type mismatch"
)
