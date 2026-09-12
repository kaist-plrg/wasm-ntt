(assert_invalid
  (module
    (memory 1)
    (data (nop))
  )
  "constant expression required"
)
