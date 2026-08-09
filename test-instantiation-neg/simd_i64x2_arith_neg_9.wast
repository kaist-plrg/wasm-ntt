(assert_invalid
  (module
    (func $i64x2.sub-arg-empty (result v128)
      (i64x2.sub)
    )
  )
  "type mismatch"
)
