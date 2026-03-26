(assert_invalid
  (module
    (func $i8x16.shl-last-arg-empty (result v128)
      (i8x16.shl (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0))
    )
  )
  "type mismatch"
)
