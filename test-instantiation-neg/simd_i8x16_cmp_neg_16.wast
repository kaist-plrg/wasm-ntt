(assert_invalid
  (module
    (func $i8x16.lt_s-arg-empty (result v128)
      (i8x16.lt_s)
    )
  )
  "type mismatch"
)
