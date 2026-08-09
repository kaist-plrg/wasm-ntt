(assert_invalid
  (module
    (func $i16x8.shr_u-last-arg-empty (result v128)
      (i16x8.shr_u (v128.const i16x8 0 0 0 0 0 0 0 0))
    )
  )
  "type mismatch"
)
