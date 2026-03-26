(assert_invalid
  (module
    (func $v128.or-1st-arg-empty (result v128)
      (v128.or (v128.const i32x4 0 0 0 0))
    )
  )
  "type mismatch"
)
