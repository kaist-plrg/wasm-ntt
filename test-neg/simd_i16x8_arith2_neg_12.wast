(assert_invalid
  (module
    (func $i16x8.max_s-arg-empty (result v128)
      (i16x8.max_s)
    )
  )
  "type mismatch"
)
