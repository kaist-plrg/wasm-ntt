(assert_invalid
  (module
    (func $i16x8.lt_s-arg-empty (result v128)
      (i16x8.lt_s)
    )
  )
  "type mismatch"
)
