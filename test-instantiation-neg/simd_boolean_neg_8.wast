(assert_invalid
  (module
    (func $i8x16.all_true-arg-empty (result v128)
      (i8x16.all_true)
    )
  )
  "type mismatch"
)
