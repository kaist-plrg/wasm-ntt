(assert_invalid
  (module
    (func $i32x4.shr_s-1st-arg-empty (result v128)
      (i32x4.shr_s (i32.const 0))
    )
  )
  "type mismatch"
)
