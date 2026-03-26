(assert_invalid
  (module
    (func $i64x2.shl-1st-arg-empty (result v128)
      (i64x2.shl (i32.const 0))
    )
  )
  "type mismatch"
)
