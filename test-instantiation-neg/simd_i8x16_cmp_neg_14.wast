(assert_invalid
  (module
    (func $i8x16.ne-arg-empty (result v128)
      (i8x16.ne)
    )
  )
  "type mismatch"
)
