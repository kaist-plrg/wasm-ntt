(assert_invalid
  (module (memory 0)
    (func $v128.load32x2_s-arg-empty (result v128)
      (v128.load32x2_s)
    )
  )
  "type mismatch"
)
