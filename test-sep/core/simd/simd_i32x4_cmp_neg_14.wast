(assert_invalid
  (module
    (func $i32x4.ne-arg-empty (result v128)
      (i32x4.ne)
    )
  )
  "type mismatch"
)
