(assert_invalid
  (module
    (func $f32x4.neg-arg-empty (result v128)
      (f32x4.neg)
    )
  )
  "type mismatch"
)
