(assert_invalid
  (module
    (func $i16x8.ne-arg-empty (result v128)
      (i16x8.ne)
    )
  )
  "type mismatch"
)
