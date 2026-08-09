(assert_invalid
  (module
    (func $i32x4.dot_i16x8_s-arg-empty (result v128)
      (i32x4.dot_i16x8_s)
    )
  )
  "type mismatch"
)
