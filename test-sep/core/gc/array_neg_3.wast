(assert_invalid
  (module (type (array (mut (ref 1)))))
  "unknown type"
)
