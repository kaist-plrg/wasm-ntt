(assert_invalid
  (module (import "spectest" "print_i32" (func (param i32))) (export "a" (func 1)))
  "unknown function"
)
