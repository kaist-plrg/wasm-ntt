(assert_invalid
  (module
    (func $f32x4.ne-arg-empty (result v128)
      (f32x4.ne)
    )
  )
  "type mismatch"
)
