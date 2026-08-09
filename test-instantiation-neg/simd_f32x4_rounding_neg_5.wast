(assert_invalid
  (module
    (func $f32x4.ceil-arg-empty (result v128)
      (f32x4.ceil)
    )
  )
  "type mismatch"
)
