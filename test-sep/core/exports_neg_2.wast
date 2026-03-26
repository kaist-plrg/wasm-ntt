(assert_invalid
  (module (func) (export "a" (func 1)))
  "unknown function"
)
