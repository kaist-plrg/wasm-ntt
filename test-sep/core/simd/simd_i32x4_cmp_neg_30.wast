(assert_invalid
  (module
    (func $i32x4.ge_u-arg-empty (result v128)
      (i32x4.ge_u)
    )
  )
  "type mismatch"
)
