(assert_invalid
  (module
    (func $i32x4.le_u-arg-empty (result v128)
      (i32x4.le_u)
    )
  )
  "type mismatch"
)
