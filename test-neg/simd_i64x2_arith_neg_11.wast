(assert_invalid
  (module
    (func $i64x2.mul-arg-empty (result v128)
      (i64x2.mul)
    )
  )
  "type mismatch"
)
