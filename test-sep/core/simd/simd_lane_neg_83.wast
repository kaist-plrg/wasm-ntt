(assert_invalid
  (module
    (func $i8x16.shuffle-2nd-arg-empty (result v128)
      (i8x16.shuffle 0 1 2 3 5 6 6 7 8 9 10 11 12 13 14 15
        (v128.const i8x16 1 2 3 5 6 6 7 8 9 10 11 12 13 14 15 16)
      )
    )
  )
  "type mismatch"
)
