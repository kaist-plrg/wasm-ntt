(assert_invalid
  (module
    (func $i16x8.abs-arg-empty (result v128)
      (i16x8.abs)
    )
  )
  "type mismatch"
)
