(assert_invalid
  (module
    (func $f32x4.gt-1st-arg-empty (result v128)
      (f32x4.gt (v128.const f32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
