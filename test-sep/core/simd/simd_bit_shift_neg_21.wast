(assert_invalid
  (module
    (func $i32x4.shr_s-arg-empty (result v128)
      (i32x4.shr_s)
    )
  )
  "type mismatch"
)
