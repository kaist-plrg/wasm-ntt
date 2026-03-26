(assert_invalid
  (module
    (func $i32x4.ge_s-arg-empty (result v128)
      (i32x4.ge_s)
    )
  )
  "type mismatch"
)
