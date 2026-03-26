(assert_invalid
  (module (memory 0)
    (func $v128.load32x2_u-arg-empty (result v128)
      (v128.load32x2_u)
    )
  )
  "type mismatch"
)
