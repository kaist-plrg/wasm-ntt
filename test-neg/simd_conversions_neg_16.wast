(assert_invalid
  (module
    (func $i16x8.narrow_i32x4_s-arg-empty (result v128)
      (i16x8.narrow_i32x4_s)
    )
  )
  "type mismatch"
)
