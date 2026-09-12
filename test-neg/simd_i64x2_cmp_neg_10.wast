(assert_invalid
  (module
    (func $i64x2.ne-arg-empty (result v128)
      (i64x2.ne)
    )
  )
  "type mismatch"
)
