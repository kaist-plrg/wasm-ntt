(assert_invalid
  (module
    (func $v128.xor-1st-arg-empty (result v128)
      (v128.xor (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
