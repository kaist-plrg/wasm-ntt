(assert_invalid
  (module
    (func $i64x2.eq-arg-empty (result v128)
      (i64x2.eq)
    )
  )
  "type mismatch"
)
