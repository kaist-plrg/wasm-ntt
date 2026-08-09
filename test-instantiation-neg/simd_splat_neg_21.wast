(assert_invalid
  (module
    (func $i64x2.splat-arg-empty (result v128)
      (i64x2.splat)
    )
  )
  "type mismatch"
)
