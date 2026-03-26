(assert_invalid
  (module
    (func $i32x4.lt_s-arg-empty (result v128)
      (i32x4.lt_s)
    )
  )
  "type mismatch"
)
