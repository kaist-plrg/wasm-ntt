(assert_invalid
  (module
    (func $f32x4.pmin-arg-empty (result v128)
      (f32x4.pmin)
    )
  )
  "type mismatch"
)
