(assert_invalid
  (module
    (func $i8x16.ge_u-1st-arg-empty (result v128)
      (i8x16.ge_u (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0))
    )
  )
  "type mismatch"
)
