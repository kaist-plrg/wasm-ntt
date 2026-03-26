(assert_invalid
  (module
    (func $i16x8.all_true-arg-empty (result v128)
      (i16x8.all_true)
    )
  )
  "type mismatch"
)
