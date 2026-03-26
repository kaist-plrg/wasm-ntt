(assert_invalid
  (module
    (func $f32x4.add-arg-empty (result v128)
      (f32x4.add)
    )
  )
  "type mismatch"
)
