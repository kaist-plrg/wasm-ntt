(assert_invalid
  (module (memory 0) (func) (export "a" (memory 0)) (export "a" (func 0)))
  "duplicate export name"
)
