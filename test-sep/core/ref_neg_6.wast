(assert_invalid
  (module (func $func-param-invalid (param (ref 1))))
  "unknown type"
)
