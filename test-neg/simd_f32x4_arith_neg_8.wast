(assert_invalid
  (module
    (func $f32x4.sqrt-arg-empty (result v128)
      (f32x4.sqrt)
    )
  )
  "type mismatch"
)
