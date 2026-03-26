(assert_invalid
  (module (memory 0)
    (func $v128.load64_zero-arg-empty (result v128)
      (v128.load64_zero)
    )
  )
  "type mismatch"
)
