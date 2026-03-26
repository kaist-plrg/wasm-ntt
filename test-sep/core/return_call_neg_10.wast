(assert_invalid
  (module (func $unbound-func (return_call 1)))
  "unknown function"
)
