(assert_invalid
  (module (memory 0)
    (func $v128.load32_zero-arg-empty (result v128)
      (v128.load32_zero)
    )
  )
  "type mismatch"
)
