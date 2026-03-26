(assert_invalid
  (module
    (memory 1)
    (data (offset (i32.const 0) (nop)))
  )
  "constant expression required"
)
