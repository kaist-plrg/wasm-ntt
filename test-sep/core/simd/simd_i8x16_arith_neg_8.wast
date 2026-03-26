(assert_invalid
  (module
    (func $i8x16.sub-arg-empty (result v128)
      (i8x16.sub)
    )
  )
  "type mismatch"
)
