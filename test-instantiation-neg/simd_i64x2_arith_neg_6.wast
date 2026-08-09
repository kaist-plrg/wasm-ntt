(assert_invalid
  (module
    (func $i64x2.add-1st-arg-empty (result v128)
      (i64x2.add (v128.const i64x2 0 0))
    )
  )
  "type mismatch"
)
