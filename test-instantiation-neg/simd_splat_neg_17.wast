(assert_invalid
  (module
    (func $i8x16.splat-arg-empty (result v128)
      (i8x16.splat)
    )
  )
  "type mismatch"
)
