(assert_invalid
  (module
    (memory 1)
    (data (offset (nop) (i32.const 0)))
  )
  "constant expression required"
)
