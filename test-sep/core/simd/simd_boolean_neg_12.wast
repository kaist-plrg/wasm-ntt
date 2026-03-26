(assert_invalid
  (module
    (func $i32x4.all_true-arg-empty (result v128)
      (i32x4.all_true)
    )
  )
  "type mismatch"
)
