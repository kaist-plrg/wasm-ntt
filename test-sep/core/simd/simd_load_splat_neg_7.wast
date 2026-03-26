(assert_invalid
  (module (memory 0)
    (func $v128.load32_splat-arg-empty (result v128)
      (v128.load32_splat)
    )
  )
  "type mismatch"
)
