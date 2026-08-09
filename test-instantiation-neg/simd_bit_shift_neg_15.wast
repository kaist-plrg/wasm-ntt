(assert_invalid
  (module
    (func $i8x16.shl-arg-empty (result v128)
      (i8x16.shl)
    )
  )
  "type mismatch"
)
