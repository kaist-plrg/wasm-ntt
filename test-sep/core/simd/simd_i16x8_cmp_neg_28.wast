(assert_invalid
  (module
    (func $i16x8.ge_s-arg-empty (result v128)
      (i16x8.ge_s)
    )
  )
  "type mismatch"
)
