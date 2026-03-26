(assert_invalid
  (module
    (func $v128.and-arg-empty (result v128)
      (v128.and)
    )
  )
  "type mismatch"
)
