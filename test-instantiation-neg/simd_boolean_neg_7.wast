(assert_invalid
  (module
    (func $v128.any_true-arg-empty (result v128)
      (v128.any_true)
    )
  )
  "type mismatch"
)
