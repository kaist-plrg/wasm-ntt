(assert_invalid
  (module
    (func $f32x4.floor-arg-empty (result v128)
      (f32x4.floor)
    )
  )
  "type mismatch"
)
