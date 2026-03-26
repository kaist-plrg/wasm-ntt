(assert_invalid
  (module
    (func $i64x2.add-arg-empty (result v128)
      (i64x2.add)
    )
  )
  "type mismatch"
)
