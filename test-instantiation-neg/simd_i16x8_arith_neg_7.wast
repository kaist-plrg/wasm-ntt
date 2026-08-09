(assert_invalid
  (module
    (func $i16x8.add-arg-empty (result v128)
      (i16x8.add)
    )
  )
  "type mismatch"
)
