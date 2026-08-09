(assert_invalid
  (module
    (func $i8x16.ge_s-arg-empty (result v128)
      (i8x16.ge_s)
    )
  )
  "type mismatch"
)
