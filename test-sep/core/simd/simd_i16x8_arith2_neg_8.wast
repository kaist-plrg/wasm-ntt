(assert_invalid
  (module
    (func $i16x8.min_s-arg-empty (result v128)
      (i16x8.min_s)
    )
  )
  "type mismatch"
)
