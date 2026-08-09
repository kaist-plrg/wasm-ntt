(assert_invalid
  (module
    (func $i32x4.max_s-arg-empty (result v128)
      (i32x4.max_s)
    )
  )
  "type mismatch"
)
