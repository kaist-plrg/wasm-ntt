(assert_invalid
  (module
    (func $i8x16.shl-1st-arg-empty (result v128)
      (i8x16.shl (i32.const 0))
    )
  )
  "type mismatch"
)
