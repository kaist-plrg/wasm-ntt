(assert_invalid
  (module
    (func $f32x4.eq-arg-empty (result v128)
      (f32x4.eq)
    )
  )
  "type mismatch"
)
