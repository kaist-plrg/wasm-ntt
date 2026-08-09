(assert_invalid
  (module
    (func $f32x4.pmax-arg-empty (result v128)
      (f32x4.pmax)
    )
  )
  "type mismatch"
)
