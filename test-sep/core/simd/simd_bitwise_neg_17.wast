(assert_invalid
  (module
    (func $v128.not-arg-empty (result v128)
      (v128.not)
    )
  )
  "type mismatch"
)
