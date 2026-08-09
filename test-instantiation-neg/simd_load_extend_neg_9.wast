(assert_invalid
  (module (memory 0)
    (func $v128.load16x4_s-arg-empty (result v128)
      (v128.load16x4_s)
    )
  )
  "type mismatch"
)
