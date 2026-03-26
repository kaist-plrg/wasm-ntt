(assert_invalid
  (module (memory 0)
    (func $v128.load8_splat-arg-empty (result v128)
      (v128.load8_splat)
    )
  )
  "type mismatch"
)
