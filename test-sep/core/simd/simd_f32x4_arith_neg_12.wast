(assert_invalid
  (module
    (func $f32x4.sub-arg-empty (result v128)
      (f32x4.sub)
    )
  )
  "type mismatch"
)
