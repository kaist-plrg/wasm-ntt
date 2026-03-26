(assert_invalid
  (module
    (memory 1)
    (data (i64.const 0))
  )
  "type mismatch"
)
