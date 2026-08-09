(assert_invalid
  (module (func $large-func (return_call 1012321300)))
  "unknown function"
)
