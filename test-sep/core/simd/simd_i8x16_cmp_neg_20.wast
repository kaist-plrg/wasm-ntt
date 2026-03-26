(assert_invalid
  (module
    (func $i8x16.le_s-arg-empty (result v128)
      (i8x16.le_s)
    )
  )
  "type mismatch"
)
