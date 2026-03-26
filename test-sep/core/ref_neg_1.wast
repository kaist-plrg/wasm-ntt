(assert_invalid
  (module (type $type-func-param-invalid (func (param (ref 1)))))
  "unknown type"
)
