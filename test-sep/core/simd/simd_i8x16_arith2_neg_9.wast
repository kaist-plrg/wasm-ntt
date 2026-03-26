(assert_invalid
  (module
    (func $i8x16.min_s-arg-empty (result v128)
      (i8x16.min_s)
    )
  )
  "type mismatch"
)
