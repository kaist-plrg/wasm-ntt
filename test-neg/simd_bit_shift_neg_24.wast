(assert_invalid
  (module
    (func $i64x2.shr_s-arg-empty (result v128)
      (i64x2.shr_s)
    )
  )
  "type mismatch"
)
