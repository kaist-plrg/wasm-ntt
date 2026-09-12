(assert_invalid
  (module
    (func $i16x8.mul-arg-empty (result v128)
      (i16x8.mul)
    )
  )
  "type mismatch"
)
