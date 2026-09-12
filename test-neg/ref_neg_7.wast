(assert_invalid
  (module (func $func-result-invalid (result (ref 1))))
  "unknown type"
)
