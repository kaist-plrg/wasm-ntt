(assert_invalid
  (module
    (func $i32x4.eq-arg-empty (result v128)
      (i32x4.eq)
    )
  )
  "type mismatch"
)
