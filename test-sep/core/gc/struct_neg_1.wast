(assert_invalid
  (module (type (struct (field (ref 1)))))
  "unknown type"
)
