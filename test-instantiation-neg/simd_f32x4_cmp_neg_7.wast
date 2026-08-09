(assert_invalid
  (module
    (func $f32x4.eq-1st-arg-empty (result v128)
      (f32x4.eq (v128.const f32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
