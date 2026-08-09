(assert_invalid
  (module
    (func $i64x2.shr_u-last-arg-empty (result v128)
      (i64x2.shr_u (v128.const i64x2 0 0))
    )
  )
  "type mismatch"
)
