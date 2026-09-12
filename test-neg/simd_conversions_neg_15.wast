(assert_invalid
  (module
    (func $i16x8.narrow_i32x4_s-1st-arg-empty (result v128)
      (i16x8.narrow_i32x4_s (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
