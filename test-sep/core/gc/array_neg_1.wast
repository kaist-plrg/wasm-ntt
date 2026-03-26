(assert_invalid
  (module
    (type (array (mut (ref null 10))))
  )
  "unknown type"
)
