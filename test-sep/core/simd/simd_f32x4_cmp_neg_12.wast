(assert_invalid
  (module
    (func $f32x4.lt-arg-empty (result v128)
      (f32x4.lt)
    )
  )
  "type mismatch"
)
