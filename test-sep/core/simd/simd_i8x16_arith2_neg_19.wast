(assert_invalid
  (module
    (func $i8x16.popcnt-arg-empty (result v128)
      (i8x16.popcnt)
    )
  )
  "type mismatch"
)
