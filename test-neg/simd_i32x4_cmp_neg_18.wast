(assert_invalid
  (module
    (func $i32x4.lt_u-arg-empty (result v128)
      (i32x4.lt_u)
    )
  )
  "type mismatch"
)
