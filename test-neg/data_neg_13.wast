(assert_invalid
  (module
    (memory 1)
    (data (i32.ctz (i32.const 0)))
  )
  "constant expression required"
)
