(assert_invalid
  (module
    (func $i16x8.shr_u-1st-arg-empty (result v128)
      (i16x8.shr_u (i32.const 0))
    )
  )
  "type mismatch"
)
