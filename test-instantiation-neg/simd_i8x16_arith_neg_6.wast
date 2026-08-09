(assert_invalid
  (module
    (func $i8x16.add-arg-empty (result v128)
      (i8x16.add)
    )
  )
  "type mismatch"
)
