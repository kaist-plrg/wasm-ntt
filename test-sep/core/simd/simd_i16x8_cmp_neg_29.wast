(assert_invalid
  (module
    (func $i16x8.ge_u-1st-arg-empty (result v128)
      (i16x8.ge_u (v128.const i16x8 0 0 0 0 0 0 0 0))
    )
  )
  "type mismatch"
)
