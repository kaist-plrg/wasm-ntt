(assert_invalid
  (module
    (func $i16x8.le_s-arg-empty (result v128)
      (i16x8.le_s)
    )
  )
  "type mismatch"
)
