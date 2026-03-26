(assert_invalid
  (module (type $type-func-result-invalid (func (result (ref 1)))))
  "unknown type"
)
