(assert_invalid
  (module
    (func $v128.xor-arg-empty (result v128)
      (v128.xor)
    )
  )
  "type mismatch"
)
