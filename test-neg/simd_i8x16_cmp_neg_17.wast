(assert_invalid
  (module
    (func $i8x16.lt_u-1st-arg-empty (result v128)
      (i8x16.lt_u (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0))
    )
  )
  "type mismatch"
)
