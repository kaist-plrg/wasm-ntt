(assert_invalid
  (module
    (func $i32x4.min_s-arg-empty (result v128)
      (i32x4.min_s)
    )
  )
  "type mismatch"
)
