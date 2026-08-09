(assert_invalid
  (module
    (func $i32x4.neg-arg-empty (result v128)
      (i32x4.neg)
    )
  )
  "type mismatch"
)
