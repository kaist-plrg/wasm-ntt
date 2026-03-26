(assert_invalid
  (module
    (func $v128.or-arg-empty (result v128)
      (v128.or)
    )
  )
  "type mismatch"
)
