(assert_invalid
  (module
    (func $i16x8.splat-arg-empty (result v128)
      (i16x8.splat)
    )
  )
  "type mismatch"
)
