(assert_invalid
  (module (func $func-local-invalid (local (ref null 1))))
  "unknown type"
)
