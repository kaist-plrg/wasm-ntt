(assert_invalid
  (module (memory 0)
    (func $v128.load8x8_u-arg-empty (result v128)
      (v128.load8x8_u)
    )
  )
  "type mismatch"
)
