(assert_invalid
  (module
    (func $i32x4.mul-arg-empty (result v128)
      (i32x4.mul)
    )
  )
  "type mismatch"
)
