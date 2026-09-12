(assert_invalid
  (module (type (struct (field (mut (ref 1))))))
  "unknown type"
)
