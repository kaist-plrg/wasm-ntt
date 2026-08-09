(assert_invalid
  (module
    (func $i64x2.abs-arg-empty (result v128)
      (i64x2.abs)
    )
  )
  "type mismatch"
)
